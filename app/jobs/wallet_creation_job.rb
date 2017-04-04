class WalletCreationJob < ActiveJob::Base

  def perform(resource_type, resource_id)
    Payments::BTC::CreateWalletService.call(resource_type, resource_id)
  end
end
