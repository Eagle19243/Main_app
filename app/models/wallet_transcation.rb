class WalletTranscation < ActiveRecord::Base
  belongs_to :task
  validates :user_wallet, :amount, presence: true
  validates :amount ,numericality: { only_integer: true,greater_than_or_equal_to:1}
end
