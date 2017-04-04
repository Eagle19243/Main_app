FactoryGirl.define do
  factory :lead_editor_request, class: ApplyRequest do
    association :user, factory: :confirmed_user
    association :project, factory: :project
    request_type :Lead_Editor
  end

  factory :coordinator_request, class: ApplyRequest do
    association :user, factory: :confirmed_user
    association :project, factory: :project
    request_type :Coordinator
  end
end
