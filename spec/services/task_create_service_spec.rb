require 'rails_helper'

RSpec.describe TaskCreateService do
  let(:user) { FactoryGirl.create(:user) }
  let(:project) { FactoryGirl.create(:project) }
  let(:task_attributes) do
    {
      title: "Test Title",
      budget: "0.015",
      deadline: "2017-03-07 17:56 PM",
      target_number_of_participants: "1",
      proof_of_execution: "Test proof",
      condition_of_execution: "Test condition_of_execution"
    }
  end

  it "performs accepted task creation when valid parameters are given" do
    task_attributes.merge!(state: "accepted")
    service = described_class.new(task_attributes, user, project)

    expect(service.create_task).to be true
    expect(service.task).to be_persisted
    expect(service.task.wallet).to be_nil
    expect(service.task).to be_accepted
    expect(service.task.project).to eq(project)
  end

  it "performs suggested task creation when valid parameters are given" do
    task_attributes.merge!(state: "suggested_task")
    service = described_class.new(task_attributes, user, project)

    expect(service.create_task).to be true
    expect(service.task).to be_persisted
    expect(service.task).to be_suggested_task
    expect(service.task.wallet).to be_nil
    expect(service.task.project).to eq(project)
  end

  it "creates an activity for a creator user" do
    task_attributes.merge!(state: "accepted")
    service = described_class.new(task_attributes, user, project)

    expect {
      service.create_task
    }.to change { Activity.count }.by(1)

    activity = user.activities.first
    expect(activity.targetable_id).to eq(service.task.id)
    expect(activity.targetable_type).to eq("Task")
  end

  it "returns false if task's budget is less than a minimum" do
    task_attributes.merge!(
      state: "accepted",
      budget: (Task::MINIMUM_FUND_BUDGET - 1) / 10e8,
      satoshi_budget: Task::MINIMUM_FUND_BUDGET - 1
    )

    service = described_class.new(task_attributes, user, project)
    expect(service.create_task).to be false
    expect(service.task.errors.first).to eq(
      [:budget, "must be higher than a minimum budget"]
    )
  end
end
