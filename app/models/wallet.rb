class Wallet < ActiveRecord::Base
  belongs_to :wallet_owner, polymorphic: true

  scope :user_wallets , -> {where('wallet_owner_type = ?', 'User')}
  scope :task_wallets , -> {where('wallet_owner_type = ?', 'Task')}

  def user_wallet?
  end

  def task_wallet?
  end

  def update_balance!
    wallet_handler = Payments::BTC::WalletHandler.new
    self.balance = wallet_handler.get_wallet_balance(wallet_id)
    save!
  end

end
