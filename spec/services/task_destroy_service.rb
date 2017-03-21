require 'rails_helper'

RSpec.describe TaskDestroyService, vcr: { cassette_name: 'bitgo' } do
  let(:task) { FactoryGirl.create(:task, :with_associations) }
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
      expect(task.wallet_address).to be_nil

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

  context "when task has wallet_address" do
    let(:wallet) { FactoryGirl.create(:wallet_address, wallet_id: 'wallet_id1') }
    let(:task) { FactoryGirl.create(:task, :with_associations, wallet_address: wallet) }

    context "when task has zero balance" do
      it "destroys a task" do
        # Make sure task's wallet is not empty
        expect(task.wallet_address).not_to be_nil

        # Run service with balance request mocked to zero
        VCR.use_cassette("bitgo_wallet_id1_zero_balance") do
          service = described_class.new(task, user)
          expect(service.destroy_task).to be true
        end

        # Expectations
        aggregate_failures("db changes is correct") do
          expect(task_existence).to be false
          expect(activity_existence).to be true
        end
      end
    end

    context "when task has non-zero balance" do
      it "does not destroy a task" do
        # Make sure task's wallet is not empty
        expect(task.wallet_address).not_to be_nil

        # Run service with balance request mocked to non-zero
        VCR.use_cassette("bitgo_wallet_id1_non_zero_balance") do
          service = described_class.new(task, user)
          expect(service.destroy_task).to be false
        end

        # Expectations
        aggregate_failures("db changes is correct") do
          expect(task_existence).to be true
          expect(activity_existence).to be false
        end
      end
    end
  end
end
