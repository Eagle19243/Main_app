require 'rails_helper'
require 'coinbase/wallet'

RSpec.describe TaskDestroyService do
  let(:task) { FactoryGirl.create(:task, :with_user, :with_project) }
  let(:user) { task.user }
  let(:project) { task.project }
  let(:task_existence) { Task.exists?(id: task.id) }
  let(:activity_existence) do
    Activity.exists?(
      targetable_id: task.id,
      targetable_type: 'Task',
      user_id: user.id,
      action: 'deleted'
    )
  end

  context "when task has no wallet_address" do
    it "destroys it" do
      # Make sure task's wallet is empty
      expect(task.wallet).to be_nil

      # Run service
      service = described_class.new(task, user)
      expect(service.destroy_task).to be true

      # Expectations
      aggregate_failures("db changes is correct") do
        expect(service.destroy_task).to be true
        expect(task_existence).to be false
        expect(activity_existence).to be true
      end
    end
  end

  context "when task has a wallet" do
    let(:task) { FactoryGirl.create(:task, :with_associations) }
    let!(:wallet) { create(:wallet, wallet_id: "test-wallet-id", wallet_owner_id: task.id, wallet_owner_type: 'Task') }

    before do
      task.reload
    end

    context "when task has zero balance", vcr: { cassette_name: 'coinbase/wallet_with_zero_balance' } do
      it "destroys a task" do
        # Make sure task's wallet is not empty
        expect(task.wallet).not_to be_nil

        # Run service with balance request mocked to zero
        service = described_class.new(task, user)
        expect(service.destroy_task).to be true

        # Expectations
        aggregate_failures("db changes is correct") do
          expect(task_existence).to be false
          expect(activity_existence).to be true
        end
      end
    end

    context "when task has non-zero balance", vcr: { cassette_name: 'coinbase/wallet_with_non_zero_balance' } do
      it "does not destroy a task" do
        # Make sure task's wallet is not empty
        expect(task.wallet).not_to be_nil

        # Run service with balance request mocked to non-zero
        service = described_class.new(task, user)
        expect(service.destroy_task).to be false

        # Expectations
        aggregate_failures("db changes is correct") do
          expect(task_existence).to be true
          expect(activity_existence).to be false
        end
      end
    end

    context "when task's balance failed to update" do
      before do
        allow_any_instance_of(Coinbase::Wallet::Client).to receive(:account) do
          raise Coinbase::Wallet::APIError
        end
      end

      it "raises general error" do
        service = described_class.new(task, user)

        expect {
          service.destroy_task
        }.to raise_error(Payments::BTC::Errors::GeneralError, "Coinbase API error")
      end
    end
  end
end
