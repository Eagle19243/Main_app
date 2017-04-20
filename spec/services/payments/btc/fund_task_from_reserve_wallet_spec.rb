require 'rails_helper'

RSpec.shared_examples "validating amount" do
  let(:min_amount) { Payments::BTC::FundTaskFromReserveWallet::MIN_AMOUNT }

  it "raise an error when amount is not a number" do
    expect {
      described_class.new(
        task: task,
        user: user,
        usd_amount: "50.00",
        stripe_token: stripe_token,
        card_id: card_id,
        save_card: save_card
      )
    }.to raise_error(
      Payments::BTC::Errors::TransferError,
      "Amount type is incorrect"
    )
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
    invalid_amount = min_amount - 0.1

    expect {
      described_class.new(
        task: task,
        user: user,
        usd_amount: invalid_amount,
        stripe_token: stripe_token,
        card_id: card_id,
        save_card: save_card
      )
    }.to raise_error(
      Payments::BTC::Errors::TransferError,
      "Amount can't be less than minimum donation ($#{min_amount})"
    )
  end
end

RSpec.describe Payments::BTC::FundTaskFromReserveWallet do
  let(:stripe_helper) { StripeMock.create_test_helper }
  let(:task) { FactoryGirl.create(:task, :with_associations) }
  let(:user) { FactoryGirl.create(:user) }
  let(:usd_amount) { 23.88 }
  let(:stripe_token) { stripe_helper.generate_card_token }
  let(:card_id) { "card-id" }
  let(:save_card) { "true" }

  before { StripeMock.start }
  after { StripeMock.stop }

  context "skip_wallet_transaction == true" do
    before do
      stub_env('skip_wallet_transaction', 'true')
    end

    context "reserve_wallet_id is blank" do
      before do
        stub_env('reserve_wallet_id', nil)
      end

      describe '#initialize' do
        it_behaves_like "validating amount"

        it "allows service object initialization" do
          service = described_class.new(
            task: task,
            user: user,
            usd_amount: 100.0,
            stripe_token: stripe_token,
            card_id: card_id,
            save_card: save_card
          )

          aggregate_failures("service object is correct") do
            expect(service.task).to eq(task)
            expect(service.user).to eq(user)
            expect(service.usd_amount).to eq(100.0)
            expect(service.stripe_token).to eq(stripe_token)
            expect(service.card_id).to eq(card_id)
            expect(service.save_card).to eq(save_card)
            expect(service.skip_wallet_transaction).to eq("true")
            expect(service.reserve_wallet_id).to eq("")
            expect(service.usd_commission_amount).to eq(9.41)
            expect(service.usd_amount_to_send).to eq(90.59)
            expect(service.satoshi_amount).to eq(7_371_273)
          end
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

        context "with just stripe token" do
          let(:card_id) { nil }
          let(:save_card) { nil }

          context "skipping coinbase transfer call" do
            let(:task) { FactoryGirl.create(:task, :with_user, :with_project) }

            let(:task_wallet) do
              FactoryGirl.create(:wallet, wallet_id: 'test-wallet-id')
            end

            before do
              task_wallet.wallet_owner = task
              task_wallet.save

              task.reload
            end

            it "doesn't raise an error" do
              expect {
                VCR.use_cassette("coinbase/wallet_with_zero_balance") do
                  fund_task_service.submit!
                end
              }.not_to raise_error

              db_record = StripePayment.where(task_id: task.id, user_id: user.id).first

              expect(db_record).not_to be_nil

              aggregate_failures("created record in db is correct") do
                expect(db_record.amount).to eq(fund_task_service.usd_amount)
                expect(db_record.amount_in_satoshi).to eq(fund_task_service.satoshi_amount.to_s)
                expect(db_record.stripe_token).to eq(fund_task_service.stripe_token)
                expect(db_record.stripe_response_id).to eq("test_ch_3")
                expect(db_record.balance_transaction).to eq("test_txn_1")
                expect(db_record.paid).to be true
                expect(db_record.refund_url).to eq("/v1/charges/test_ch_3/refunds")
                expect(db_record.status).to eq("succeeded")
                expect(db_record.seller_message).to be_nil
                expect(db_record.transferd).to be false
                expect(db_record.tx_id).to be_nil
                expect(db_record.tx_hex).to be_nil
                expect(db_record.tx_internal_id).to be_nil
              end
            end
          end

          context "when task has no wallet yet", vcr: { cassette_name: 'coinbase/wallet_creation' } do
            let(:task) { FactoryGirl.create(:task, :with_user, :with_project) }

            it "creates a wallet for a task" do
              expect(task.wallet).to be_nil

              expect {
                fund_task_service.submit!
              }.not_to raise_error

              wallet = Task.find(task.id).wallet

              aggregate_failures("wallet is correct") do
                expect(wallet).not_to be_nil
                expect(wallet.wallet_id).to eq("2a544ef7-23e3-59d9-976c-7f80bbedaf77")
                expect(wallet.receiver_address).to eq("")
              end
            end
          end
        end
      end
    end

    context "reserve_wallet_id is not blank" do
      before do
        stub_env('reserve_wallet_id', '30a21ed2-4f04-57ae-9d21-becb751138f4')
      end

      describe '#initialize' do
        it "raises an error because reserve_wallet_id does not make sense when skip_wallet_transaction is true" do
          expect {
            described_class.new(
              task: task,
              user: user,
              usd_amount: 100.0,
              stripe_token: stripe_token,
              card_id: card_id,
              save_card: save_card
            )
          }.to raise_error(
            Payments::BTC::Errors::TransferError,
            "Environment configuration is incorrect. Please check ENV variables"
          )
        end
      end
    end
  end

  context "skip_wallet_transaction is not set" do
    before do
      stub_env('skip_wallet_transaction', nil)
    end

    context "reserve_wallet_id is blank" do
      describe '#initialize' do
        before do
          stub_env('reserve_wallet_id', nil)
        end

        it "raise an error" do
          expect {
            described_class.new(
              task: task,
              user: user,
              usd_amount: 100.0,
              stripe_token: stripe_token,
              card_id: card_id,
              save_card: save_card
            )
          }.to raise_error(
            Payments::BTC::Errors::TransferError,
            "Environment configuration is incorrect. Please check ENV variables"
          )
        end
      end
    end

    context "env vars are correct" do
      before do
        stub_env('reserve_wallet_id', '30a21ed2-4f04-57ae-9d21-becb751138f4')
      end

      describe '#initialize' do
        it_behaves_like "validating amount"

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
            expect(task_fund_service.usd_commission_amount).to eq(2.45)
            expect(task_fund_service.usd_amount_to_send).to eq(21.43)
            expect(task_fund_service.satoshi_amount).to eq(1743750)
            expect(task_fund_service.stripe_token).to eq(stripe_token)
            expect(task_fund_service.card_id).to eq(card_id)
            expect(task_fund_service.save_card).to eq(save_card)
            expect(task_fund_service.skip_wallet_transaction).to eq("")
            expect(task_fund_service.reserve_wallet_id).to eq("30a21ed2-4f04-57ae-9d21-becb751138f4")
          end
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
            'Not Enough BTC in Reserve wallet. Please Try Again'
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

            context "when coinbase call is successful" do
              it "doesn't raise an error" do
                VCR.use_cassette("coinbase/transfer/success") do
                  expect {
                    fund_task_service.submit!
                  }.not_to raise_error

                  db_record = StripePayment.where(task_id: task.id, user_id: user.id).first

                  expect(db_record).not_to be_nil

                  aggregate_failures("created record in db is correct") do
                    expect(db_record.amount).to eq(fund_task_service.usd_amount)
                    expect(db_record.amount_in_satoshi).to eq(fund_task_service.satoshi_amount.to_s)
                    expect(db_record.stripe_token).to eq(fund_task_service.stripe_token)
                    expect(db_record.stripe_response_id).to eq("test_ch_3")
                    expect(db_record.balance_transaction).to eq("test_txn_1")
                    expect(db_record.paid).to be true
                    expect(db_record.refund_url).to eq("/v1/charges/test_ch_3/refunds")
                    expect(db_record.status).to eq("succeeded")
                    expect(db_record.seller_message).to be_nil
                    expect(db_record.transferd).to be true
                    expect(db_record.tx_id).to be_nil
                    expect(db_record.tx_hex).to be_nil
                    expect(db_record.tx_internal_id).to eq(
                      "0a081224-1198-5098-9076-e811f3135b13"
                    )
                  end

                  task.wallet.reload
                  task.reload
                  expect(task.wallet.balance).to eq(100000000)
                  expect(task.current_fund).to eq(100000000)
                end
              end

              context "when task has no wallet yet", vcr: { cassette_name: 'coinbase/wallet_creation' } do
                let(:task) { FactoryGirl.create(:task, :with_user, :with_project) }

                it "creates a wallet for a task" do
                  expect(task.wallet).to be_nil

                  VCR.use_cassette("coinbase/transfer/success") do
                    expect {
                      fund_task_service.submit!
                    }.not_to raise_error
                  end

                  wallet = Task.find(task.id).wallet

                  aggregate_failures("wallet is correct") do
                    expect(wallet).not_to be_nil
                    expect(wallet.wallet_id).to eq("2a544ef7-23e3-59d9-976c-7f80bbedaf77")
                    expect(wallet.receiver_address).to eq("")
                  end

                  task.wallet.reload
                  task.reload
                  expect(task.wallet.balance).to eq(100000000)
                  expect(task.current_fund).to eq(100000000)
                end
              end
            end
          end
        end
      end
    end
  end
end
