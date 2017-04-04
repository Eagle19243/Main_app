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
end
