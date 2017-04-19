require 'rails_helper'

RSpec.describe Task, :type => :model do
  describe "validations" do
    it "is not possible to create a task without a deadline" do
      expect {
        create(:task, deadline: nil)
      }.to raise_error(
        ActiveRecord::RecordInvalid,
        "Validation failed: Deadline can't be blank"
      )
    end

    it "is not possible to set a nil deadline for a valid task" do
      task = create(:task, deadline: "2017-03-24 11:17:46 UTC")
      task.deadline = nil
      expect(task.save).to be false
    end

    it "is possible to create a task with a deadline" do
      task = create(:task, deadline: "2017-03-24 11:17:46 UTC")
      expect(task).to be_persisted
    end
  end

  describe 'state transitions' do
    describe '#reject' do
      it { is_expected.to transition_from(:pending).to(:rejected).on_event(:reject) }
      it { is_expected.to transition_from(:suggested_task).to(:rejected).on_event(:reject) }
      it { is_expected.to transition_from(:accepted).to(:rejected).on_event(:reject) }
    end
  end

  describe 'task wallet creation' do
    it 'does not create wallet for a pending task' do
      task = create(:task, :pending)
      task.reload
      expect(task.wallet).not_to be_present
    end

    it 'does not create wallet for a suggested_task task' do
      task = create(:task, :suggested, user: create(:user, :confirmed_user))
      task.reload
      expect(task.wallet).not_to be_present
    end

    it 'does not create a wallet for a accepted task' do
      task = create(:task)
      task.reload
      expect(task.wallet).not_to be_present
    end

    it 'creates a wallet for a task if with_wallet trait is used' do
      task = create(:task, :with_wallet)
      task.reload
      expect(task.wallet).to be_present
    end
  end

  describe '#funds_needed_to_fulfill_budget' do
    it "returns budget if there is no any funding" do
      task = create(:task, budget: 0.012)
      expect(task.funds_needed_to_fulfill_budget).to eq(1_200_000)
    end

    it "returns difference between budget and current_fund" do
      task = create(:task, budget: 0.012, current_fund: 550_000)
      expect(task.funds_needed_to_fulfill_budget).to eq(650_000)
    end

    it "returns zero if task 100% funded" do
      task = create(:task, budget: 0.012, current_fund: 1_200_000)
      expect(task.funds_needed_to_fulfill_budget).to eq(0)
    end

    it "returns zero if task funded for the more than 100%" do
      task = create(:task, budget: 0.012, current_fund: 2_200_000)
      expect(task.funds_needed_to_fulfill_budget).to eq(0)
    end

    it "returns zero if task is already completed" do
      task = create(:task, :completed, budget: 0.012, current_fund: 0)
      expect(task.funds_needed_to_fulfill_budget).to eq(0)
    end
  end
end
