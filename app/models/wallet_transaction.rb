# Class is used as database record of performed transactions from task wallet.
#
# Important notes:
#
# - records are created when task wallet sends coins to another bitcoin address
# - it's possible that WalletTransaction is created in DB, but actual
# transaction is failed.
#
# Key fields:
#
# * amount      - amount of coins to transfer
# * user_wallet - bitcoin address to send coins to
# * task_id     - task id which should accept transfer to its wallet
class WalletTransaction < ActiveRecord::Base
  belongs_to :task

  validates :user_wallet, :amount, presence: true
  validates :amount, numericality: {
    only_decimal: true,
    greater_than_or_equal_to: 0
  }
end
