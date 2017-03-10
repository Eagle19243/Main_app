class Payments::BTC::WalletHandler

  def initialize
  end

  def get_wallet_balance(wallet_id)
    response = api.get_wallet(wallet_id: wallet_id, access_token: access_token)
    response["balance"]
  end

  def get_wallet_transactions(sender_address)
    api.list_wallet_transctions(sender_address, access_token)
  end

  private 

  def access_token
    Payments::BTC::Base.bitgo_access_token
  end

  def api
    Bitgo::V1::Api.new
  end
end
