require 'rails_helper'

RSpec.describe Payments::BTC::FundTaskFromReserveWallet, vcr: { cassette_name: 'bitgo' } do
  let(:stripe_helper) { StripeMock.create_test_helper }
  let(:task) { FactoryGirl.create(:task, :with_associations, :with_wallet) }
  let(:user) { FactoryGirl.create(:user) }
  let(:usd_amount) { "23.88" }
  let(:stripe_token) { stripe_helper.generate_card_token }
  let(:card_id) { "card-id" }
  let(:save_card) { "true" }

  before { StripeMock.start }
  after { StripeMock.stop }

  context "skip_wallet_transaction == true" do
    describe '#initialize' do
      before do
        stub_env('skip_wallet_transaction', 'true')
      end

      it "raise an error wallet transactions are not enabled" do
        expect {
          described_class.new(
            task: task,
            user: user,
            usd_amount: 0.0,
            stripe_token: stripe_token,
            card_id: card_id,
            save_card: save_card
          )
        }.to raise_error(
          Payments::BTC::Errors::TransferError,
          "Wallet transactions are not configured for this environment"
        )
      end
    end
  end

  context "reserve_wallet_id is blank" do
    describe '#initialize' do
      before do
        stub_env('reserve_wallet_id', nil)
        stub_env('reserve_wallet_pass_pharse', 'test-wallet-passphrase')
      end

      it "raise an error" do
        expect {
          described_class.new(
            task: task,
            user: user,
            usd_amount: 0.0,
            stripe_token: stripe_token,
            card_id: card_id,
            save_card: save_card
          )
        }.to raise_error(
          Payments::BTC::Errors::TransferError,
          "Reserve Wallet ID is not configured for this environment"
        )
      end
    end
  end

  context "reserve_wallet_pass_pharse is blank" do
    describe '#initialize' do
      before do
        stub_env('reserve_wallet_id', 'test-wallet-id')
        stub_env('reserve_wallet_pass_pharse', nil)
      end

      it "raise an error" do
        expect {
          described_class.new(
            task: task,
            user: user,
            usd_amount: 0.0,
            stripe_token: stripe_token,
            card_id: card_id,
            save_card: save_card
          )
        }.to raise_error(
          Payments::BTC::Errors::TransferError,
          "Reserve Wallet Passphrase is not configured for this environment"
        )
      end
    end
  end

  context "env vars are correct" do
    before do
      stub_env('reserve_wallet_id', 'test-wallet-id')
      stub_env('reserve_wallet_pass_pharse', 'test-wallet-passphrase')
    end

    describe '#initialize' do
      it "creates fund service object with valid parameters" do
        task_fund_service = described_class.new(
          task: task,
          user: user,
          usd_amount: usd_amount,
          stripe_token: stripe_token,
          card_id: card_id,
          save_card: save_card
        )
        aggregate_failures("fund service object is correct") do
          expect(task_fund_service.task).to eq(task)
          expect(task_fund_service.user).to eq(user)
          expect(task_fund_service.usd_amount).to eq(usd_amount)
          expect(task_fund_service.satoshi_amount).to eq(1943106)
          expect(task_fund_service.stripe_token).to eq(stripe_token)
          expect(task_fund_service.card_id).to eq(card_id)
          expect(task_fund_service.save_card).to eq(save_card)
        end
      end

      it "raise an error when amount is 0" do
        expect {
          described_class.new(
            task: task,
            user: user,
            usd_amount: 0.0,
            stripe_token: stripe_token,
            card_id: card_id,
            save_card: save_card
          )
        }.to raise_error(
          Payments::BTC::Errors::TransferError,
          "Amount can't be blank"
        )
      end

      it "raise an error when amount is less than min donation size" do
        expect {
          described_class.new(
            task: task,
            user: user,
            usd_amount: 5,
            stripe_token: stripe_token,
            card_id: card_id,
            save_card: save_card
          )
        }.to raise_error(
          Payments::BTC::Errors::TransferError,
          "Amount can't be less than minimum donation"
        )
      end

      it "raise an error when task has no wallet to accept funds" do
        task_without_wallet = FactoryGirl.create(:task)

        expect {
          described_class.new(
            task: task_without_wallet,
            user: user,
            usd_amount: 50.0,
            stripe_token: stripe_token,
            card_id: card_id,
            save_card: save_card
          )
        }.to raise_error(
          Payments::BTC::Errors::TransferError,
          "Task's wallet doesn't exist"
        )
      end
    end

    describe '#submit' do
      let(:fund_task_service) do
        described_class.new(
          task: task,
          user: user,
          usd_amount: usd_amount,
          stripe_token: stripe_token,
          card_id: card_id,
          save_card: save_card
        )
      end

      it "raises an error when reserve balance has not enough balance" do
        allow_any_instance_of(
          Payments::BTC::WalletHandler
        ).to receive(:get_wallet_balance).and_return(100_000)

        expect {
          fund_task_service.submit!
        }.to raise_error(
          Payments::BTC::Errors::TransferError, 
          'Not Enough BTC in Reserve wallet Please Try Again.'
        )
      end

      context 'when there are enough funds in reserve wallet' do
        before do
          allow_any_instance_of(
            Payments::BTC::WalletHandler
          ).to receive(:get_wallet_balance).and_return(100_000_000)
        end

        it "raises an error in case of declined card" do
          StripeMock.prepare_card_error(:card_declined)

          expect {
            fund_task_service.submit!
          }.to raise_error(
            Payments::BTC::Errors::TransferError,
            "The card was declined"
          )
        end

        context "with just stripe token" do
          let(:card_id) { nil }
          let(:save_card) { nil }

          context "when bitgo call is successful" do
            it "doesn't raise an error" do
              VCR.use_cassette("bitgo_transaction_success") do
                expect {
                  fund_task_service.submit!
                }.not_to raise_error

                db_record = StripePayment.where(task_id: task.id, user_id: user.id).first

                expect(db_record).not_to be_nil

                aggregate_failures("created record in db is correct") do
                  expect(db_record.amount.to_s).to eq(fund_task_service.usd_amount)
                  expect(db_record.amount_in_satoshi).to eq(fund_task_service.satoshi_amount.to_s)
                  expect(db_record.stripe_token).to eq(fund_task_service.stripe_token)
                  expect(db_record.stripe_response_id).to eq("test_ch_3")
                  expect(db_record.balance_transaction).to eq("test_txn_1")
                  expect(db_record.paid).to be true
                  expect(db_record.refund_url).to eq("/v1/charges/test_ch_3/refunds")
                  expect(db_record.status).to eq("succeeded")
                  expect(db_record.seller_message).to be_nil
                  expect(db_record.transferd).to be true
                  expect(db_record.tx_id).to eq("returned-transaction-id")
                  expect(db_record.tx_hex).to eq("returned-transaction-hex")
                end
              end
            end
          end
        end
      end
    end
  end
end
