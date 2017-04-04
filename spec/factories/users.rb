FactoryGirl.define do
  factory :user do
    sequence(:email) { |n| "test_user#{n}@example.com"}
    password 'secretadmin0password'
    sequence(:name) { |n| "Test#{n} User"}
    sequence(:username) { |n| "username#{n}"}

    trait :confirmed_user do
      confirmed_at DateTime.now
    end

    trait :with_wallet do
      association :wallet
    end
  end
end
