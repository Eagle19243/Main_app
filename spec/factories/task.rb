FactoryGirl.define do
  factory :task do
    sequence(:title) { |n| "task #{n}" }
    budget 0
    target_number_of_participants 0
    sequence(:condition_of_execution) { |n| "condition_of_execution #{n}" }
    sequence(:proof_of_execution) { |n| "proof_of_execution #{n}" }
    sequence(:deadline) { |n| n.days.from_now }
    state "accepted"
  end


  factory :task_with_associations, class: Task do
    title 'This is a task'
    association :user, :confirmed_user, factory: :user
    association :project, factory: :base_project
    state 'pending'
    budget 100
    deadline 30.days.from_now
  end
end
