set :output, {:standard => nil}
env :PATH, ENV['PATH']
set :environment, ENV['RAILS_ENV']

every 1.minute do
  rake "weserve:fetch_btc_exchange_rate"
end
