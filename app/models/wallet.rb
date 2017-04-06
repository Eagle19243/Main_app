class Wallet < ActiveRecord::Base
  belongs_to :wallet_owner, polymorphic: true

  scope :user_wallets , -> {where('wallet_owner_type = ?', 'User')}
  scope :task_wallets , -> {where('wallet_owner_type = ?', 'Task')}

  def user_wallet?
  end

  def task_wallet?
  end
end
