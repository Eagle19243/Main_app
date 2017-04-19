require 'coinbase/wallet'

namespace :weserve do
  desc "Fetch curent BTC rate"
  task fetch_btc_exchange_rate: :environment do
    client = Coinbase::Wallet::Client.new(
        api_key:    Payments::BTC::Base.coinbase_api_key,
        api_secret: Payments::BTC::Base.coinbase_api_secret
    )

    BtcExchangeRate.create(rate: client.spot_price.amount)
  end

  desc "Update balances for wallets"
  task update_wallets_balance: :environment do
    updater = Payments::BTC::BulkUpdater.new
    updater.update_all_wallets_balance!
  end

  desc "Update tx_hash for transactions"
  task update_tx_hash_for_transactions: :environment do
    updater = Payments::BTC::BulkUpdater.new
    updater.update_tx_hash_for_transactions!
  end

  desc "Update receiving addresses for wallets"
  task update_wallets_receiver_address: :environment do
    updater = Payments::BTC::BulkUpdater.new
    updater.update_all_wallets_receiver_address!
  end

  desc 'Checks reserve wallet balance and norifies admin in case balance is too low'
  task check_reserve_wallet_balance: :environment do
    if ENV['reserve_wallet_id'].present?
      reerve_wallet_balance  = Payments::BTC::WalletHandler.new.get_wallet_balance(ENV['reserve_wallet_id'])
      ApplicationMailer.reserve_wallet_low_balance(reerve_wallet_balance).deliver_later if reerve_wallet_balance <= 50_000_000
    end
  end
end
