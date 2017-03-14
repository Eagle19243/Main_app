Payments::BTC::Base.configure(
  weserve_fee:                ENV['weserve_service_fee'],
  bitgo_fee:                  ENV['bitgo_service_fee'],
  weserve_wallet_address:     ENV['weserve_wallet_address'],
  bitgo_access_token:         ENV['bitgo_admin_access_token'],
  bitgo_reserve_access_token: ENV['bitgo_admin_weserve_admin_access_token']
)
