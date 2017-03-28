require 'rails_helper'

RSpec.describe Payments::BTC::FundTask, vcr: { cassette_name: 'bitgo' } do
  let(:task) { FactoryGirl.create(:task, :with_associations, :with_wallet) }
  let(:user) { User.find(task.user_id) }
  let(:amount) { described_class::MIN_AMOUNT }

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

      it "raises an error if amount is less than minimum" do
        invalid_amount = amount - 1

        expect {
          described_class.new(amount: invalid_amount, task: task, user: user)
        }.to raise_error(
          Payments::BTC::Errors::TransferError,
          "Amount can't be less than minimum allowed size"
        )
      end
    end

    context "when arguments are valid" do
      context "when task has no wallet address yet" do
        let(:task) { FactoryGirl.create(:task, :with_associations) }

        it "creates a wallet for a task" do
          expect(task.wallet_address).to be_nil

          described_class.new(amount: amount, task: task, user: user)
          expect(Task.find(task.id).wallet_address).not_to be_nil
        end
        
      end

      context "when task has wallet address yet" do
        let(:task) { FactoryGirl.create(:task, :with_associations, :with_wallet) }

        it "initialize fund btc address service" do
          service = described_class.new(amount: amount, task: task, user: user)

          aggregate_failures("fund btc address object is correct") do
            expect(service.fund_btc_address).to be_kind_of(Payments::BTC::FundBtcAddress)
            expect(service.fund_btc_address.amount).to eq(amount)
            expect(service.fund_btc_address.address_to).to eq(task.wallet_address.receiver_address)
            expect(service.fund_btc_address.user).to eq(user)
          end
        end
      end
    end
  end
end
