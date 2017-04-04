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

  desc "Update receiving addresses for wallets"
  task update_wallets_receiver_address: :environment do
    updater = Payments::BTC::BulkUpdater.new
    updater.update_all_wallets_receiver_address!
  end
end
