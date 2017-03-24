namespace :weserve do
  desc "Fetch curent BTC rate"
  task fetch_btc_exchange_rate: :environment do
    response ||= RestClient.get 'https://www.bitstamp.net/api/ticker/'
    btc=JSON.parse(response)['last']
    BtcExchangeRate.create(rate: btc.to_f)
  end

  desc "Update balances for tasks"
  task update_tasks_balances: :environment do
    updater = Payments::BTC::BulkTaskBalanceUpdater.new
    updater.update_all_accepted_tasks!
  end
end
