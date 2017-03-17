class WalletCreationJob < ActiveJob::Base

  def perform(resource_type, resource_id)
    case resource_type
    when 'User'
      Payments::BTC::CreateUserWalletService.call(resource_id)
    when 'Task'
      Payments::BTC::CreateTaskWalletService.call(resource_id)
    end
  end
end
