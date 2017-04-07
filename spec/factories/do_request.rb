FactoryGirl.define do
  factory :do_request, class: DoRequest do
    association :user, :confirmed_user, factory: :user
    association :project, factory: :project, picture: nil
    application "Test application"
  end
end
