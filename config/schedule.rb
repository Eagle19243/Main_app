set :output, {:standard => nil}
env :PATH, ENV['PATH']
set :environment, ENV['RAILS_ENV']

every 1.minute do
  rake "weserve:fetch_btc_exchange_rate"
end

every 10.minutes do
  rake "weserve:update_wallets_balance"
end

every 10.minutes do
  rake "weserve:check_reserve_wallet_balance"
end

every 1.day do
  rake "weserve:update_tx_hash_for_transactions"
end

every 1.week do
  rake "weserve:update_wallets_receiver_address"
end

every 1.day, :at => '5:30 am' do
  rake "task_summary:send_summary_notification"
end
