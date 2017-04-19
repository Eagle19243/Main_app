require 'rails_helper'

RSpec.describe Payments::BTC::FundTask do
  let(:task) { FactoryGirl.create(:task, :with_associations) }
  let(:amount) { described_class::MIN_AMOUNT }
  let(:min_amount_in_btc) { Payments::BTC::Converter.convert_satoshi_to_btc(amount) }
  let(:user) { User.find(task.user_id) }
  let!(:wallet) { create(:wallet, wallet_id: "30a21ed2-4f04-57ae-9d21-becb751138f4", wallet_owner_id: user.id, wallet_owner_type: 'User') }

  before do
    user.reload
  end

  describe "#initialize" do
    context "when arguments are invalid" do
      it "raises an error if task argument is incorrect" do
        fake_task = "fake task"

        expect {
          described_class.new(amount: amount, task: fake_task, user: user)
        }.to raise_error(
          Payments::BTC::Errors::TransferError,
          "Task argument is invalid"
        )
      end

      it "raises an error if user argument is incorrect" do
        fake_user = "fake user"

        expect {
          described_class.new(amount: amount, task: task, user: fake_user)
        }.to raise_error(
          Payments::BTC::Errors::TransferError,
          "User argument is invalid"
        )
      end

      it "raises an error if user has no wallet" do
        bad_user = create(:user)

        expect {
          described_class.new(amount: amount, task: task, user: bad_user)
        }.to raise_error(
          Payments::BTC::Errors::TransferError,
          "User's wallet doesn't exist"
        )
      end

      it "raises an error if amount is less than minimum" do
        invalid_amount = amount - 1

        expect {
          described_class.new(amount: invalid_amount, task: task, user: user)
        }.to raise_error(
          Payments::BTC::Errors::TransferError,
          "Amount can't be less than minimum allowed size (#{min_amount_in_btc} BTC)"
        )
      end
    end

    context "when arguments are valid" do
      context "when task has no wallet yet" do
        let(:task) { FactoryGirl.create(:task, :with_user, :with_project) }

        it "creates a wallet for a task", vcr: { cassette_name: 'coinbase/wallet_creation' } do
          expect(task.wallet).to be_nil

          described_class.new(amount: amount, task: task, user: user)

          wallet = Task.find(task.id).wallet

          aggregate_failures("wallet is correct") do
            expect(wallet).not_to be_nil
            expect(wallet.wallet_id).to eq("2a544ef7-23e3-59d9-976c-7f80bbedaf77")
            expect(wallet.receiver_address).to eq("")
          end
        end
      end

      context "when task already has wallet" do
        let(:task_wallet) do
          FactoryGirl.create(:wallet, wallet_id: 'test-wallet-id')
        end

        let(:task) { FactoryGirl.create(:task, :with_user, :with_project) }

        before do
          task_wallet.wallet_owner = task
          task_wallet.save

          task.reload
        end

        it "initialize transfer service" do
          service = described_class.new(amount: amount, task: task, user: user)

          aggregate_failures("transfer object is correct") do
            expect(service.transfer).to be_kind_of(Payments::BTC::InternalTransfer)
            expect(service.transfer.wallet_id).to eq(user.wallet.wallet_id)
            expect(service.transfer.address_to).to eq(task.wallet.wallet_id)
            expect(service.transfer.amount).to eq(amount)
          end
        end

        context "when transfer is submitted" do
          it "completes transfer, create record in the database and updates balances" do
            service = described_class.new(amount: amount, task: task, user: user)

            VCR.use_cassette("coinbase/wallet_with_non_zero_balance") do
              VCR.use_cassette("coinbase/transfer/success") do
                expect {
                  service.submit!
                }.not_to raise_error
              end
            end

            db_record = UserWalletTransaction.first

            aggregate_failures("created record in db is correct") do
              expect(db_record.amount).to eq(service.amount)
              expect(db_record.user_wallet).to eq(task.wallet.wallet_id)
              expect(db_record.user_id).to eq(user.id)
              expect(db_record.tx_internal_id).to eq(
                "0a081224-1198-5098-9076-e811f3135b13"
              )
            end

            task_wallet.reload
            task.reload
            expect(task_wallet.balance).to eq(20000000)
            expect(task.current_fund).to eq(20000000)
          end
        end
      end
    end
  end
end
