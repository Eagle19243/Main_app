module Payments::BTC
  # Service is responsible for updating all accepted tasks' balances.
  class BulkUpdater
    attr_reader :wallet_handler

    def initialize
      @wallet_handler ||= Payments::BTC::WalletHandler.new
    end

    def update_all_wallets_balance!
      Wallet.all.find_each do |wallet|
        unless wallet.wallet_owner.is_a?(Task) && wallet.wallet_owner.state == "completed"
          wallet.update(balance: wallet_handler.get_wallet_balance(wallet.wallet_id)) unless wallet.wallet_owner.is_a?(Task) && wallet.wallet_owner.state =="completed"
        end
      end

      # TODO We want to get rid of current_fund in future but currently is too much coupled up in the system
      Task.all.find_each do |task|
        task.update_current_fund! unless task.state == "completed"
      end
    end

    def update_all_wallets_receiver_address!
      Wallet.user_wallets.find_each do |wallet|
        wallet.update(receiver_address: wallet_handler.create_addess_for_wallet(wallet.wallet_id))
      end
    end

  end
end
