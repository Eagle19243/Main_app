FactoryGirl.define do
  factory :wallet_address do
    sequence(:sender_address) { |n| "sender#{n}@address.com" }
    sequence(:wallet_id) { |n| "wallet_id#{n}" }
    sequence(:receiver_address) { |n| "receiver#{n}@address.com" }
    current_balance 1000
  end
end
