FactoryGirl.define do
  factory :user do
    sequence(:email) { |n| "test_user#{n}@example.com"}
    password 'secretadmin0password'
    sequence(:username) { |n| "username#{n}"}
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }

    trait :confirmed_user do
      confirmed_at DateTime.now
    end

    trait :with_wallet do
      association :wallet
    end
  end
end
