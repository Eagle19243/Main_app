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
    end

    def update_tx_hash_for_transactions!
      UserWalletTransaction.where(tx_id: nil).find_each do |transaction|
        coinbase_wallet = wallet_handler.get_wallet(transaction.user.wallet.wallet_id)
        coinbase_wallet.transaction(transaction.tx_internal_id)

        coinbase_transaction = coinbase_wallet.transaction(transaction.tx_internal_id)
        hash = coinbase_transaction.fetch('network', {})['hash']

        transaction.update_attribute(:tx_id, hash)
      end
    end

    def update_all_wallets_receiver_address!
      Wallet.user_wallets.find_each do |wallet|
        wallet.update(receiver_address: wallet_handler.create_addess_for_wallet(wallet.wallet_id))
      end
    end

  end
end
