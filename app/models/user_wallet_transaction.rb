# Class is used as database record of performed transactions from user
# wallet.
#
# Important notes:
#
# - records are created when user initiates transfer from wallet to any bitcoin
# receive address.
# - it's possible that UserWalletTransaction is created in DB, but actual
# transaction is failed.
#
# Key fields:
#
# * amount      - amount of coins to transfer
# * user_wallet - bitcoin address to send coins to
# * user_id     - user id who initiated the transfer
class UserWalletTransaction < ActiveRecord::Base
  acts_as_paranoid

  belongs_to :user

  validates :user_wallet, :amount, presence: true
  validates :amount, numericality: {
    only_decimal: true,
    greater_than_or_equal_to: 0
  }
end
