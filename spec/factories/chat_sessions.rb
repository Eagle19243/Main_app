FactoryGirl.define do
  factory :chat_session do
    requester { create(:user) }
    receiver { create(:user) }
  end
end
