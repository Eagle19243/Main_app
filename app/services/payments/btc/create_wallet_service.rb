class Payments::BTC::CreateWalletService
  attr_accessor :resource, :wallet_name

  def self.call(resource_type, resource_id)
    self.new(resource_type, resource_id).call
  end

  def initialize(resource_type , resource_id)
    self.resource = fetch_resource(resource_type, resource_id)
    self.wallet_name = [Rails.env, resource_type.downcase, resource_id, "wallet"].join('_')
  end

  def call
    wallet_handler = Payments::BTC::WalletHandler.new
    coinbase_wallet = wallet_handler.create_wallet(wallet_name)
    coinbase_receiver_address = resource.is_a?(User) ? wallet_handler.create_addess_for_wallet(coinbase_wallet["id"]) : ''

    Wallet.create(wallet_id: coinbase_wallet["id"], wallet_owner: resource, receiver_address: coinbase_receiver_address)
  end

  private

  def fetch_resource(resource_type, resource_id)
    case resource_type
    when 'User'
      User.find(resource_id)
    when 'Task'
      Task.find(resource_id)
    end
  end
end
