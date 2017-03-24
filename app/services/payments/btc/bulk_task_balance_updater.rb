module Payments::BTC
  # Service is responsible for updating all accepted tasks' balances.
  class BulkTaskBalanceUpdater
    attr_reader :wallet_handler

    def initialize
      @wallet_handler ||= Payments::BTC::WalletHandler.new
    end

    def update_all_accepted_tasks!
      accepted_tasks.each { |task| update_task_balance(task) }
    end

    private
    def update_task_balance(task)
      if task.wallet_address
        balance = wallet_handler.get_wallet_balance(task.wallet_address.wallet_id)
        task.update_attribute(:current_fund, balance)
      end
    end

    def accepted_tasks
      Task.where(state: 'accepted')
    end
  end
end
