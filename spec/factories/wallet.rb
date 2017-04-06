FactoryGirl.define do
  factory :wallet do
    sequence(:wallet_id) { |n| "wallet_id#{n}" }
    sequence(:receiver_address) { |n| "receiver#{n}@address.com" }
  end
end
