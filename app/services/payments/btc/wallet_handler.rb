class Payments::BTC::WalletHandler

  def initialize
  end

  def get_wallet_balance(wallet_id)
    response = api.get_wallet(wallet_id: wallet_id, access_token: access_token)
    
    response["balance"]
  end

  def get_wallet_transactions(address)
    api.list_wallet_transctions(address, access_token)
  end

  def create_wallet(secure_passphrase, secure_label)
    response = api.simple_create_wallet(passphrase: secure_passphrase, label: secure_label, access_token: access_token)

    [response["wallet"]["id"], response["userKeychain"], response["backupKeychain"]]
  end

  def create_address(address_id, chain)
    response = api.create_address(wallet_id: address_id, chain: chain, access_token: access_token)
   
    response["address"]
  end

  def wallet_balance_confirmed?(wallet_id)
    response = api.get_wallet(wallet_id: wallet_id, access_token: access_token)

    response["balance"] == response["spendableConfirmedBalance"]
  end

  private 

  def access_token
    Payments::BTC::Base.bitgo_access_token
  end

  def api
    Bitgo::V1::Api.new
  end
end
