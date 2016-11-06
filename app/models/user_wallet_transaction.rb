class UserWalletTransaction < ActiveRecord::Base
  belongs_to :user
  validates :user_wallet, :amount, presence: true
  validates :amount ,numericality: { only_decimal: true,greater_than_or_equal_to:0}
end
