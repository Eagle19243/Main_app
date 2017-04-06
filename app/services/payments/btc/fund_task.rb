module Payments::BTC
  # Service is responsible for funding task's balance from user wallet.
  #
  # Service applies more strict validation rules and then calls
  # +Payments::BTC::FundBtcAddress+ to initiate a transfer.
  class FundTask
    MIN_AMOUNT = Task::MINIMUM_DONATION_SIZE

    attr_reader :amount, :task, :user, :transfer

    def initialize(amount:, task:, user:)
      raise Payments::BTC::Errors::TransferError, "Task argument is invalid" unless task.is_a?(Task)
      raise Payments::BTC::Errors::TransferError, "User argument is invalid" unless user.is_a?(User)
      raise Payments::BTC::Errors::TransferError, "User's wallet doesn't exist" unless user.wallet
      raise Payments::BTC::Errors::TransferError, "Amount can't be less than minimum allowed size" unless amount >= MIN_AMOUNT

      unless task.wallet
        Payments::BTC::CreateWalletService.call("Task", task.id)
        task.reload
      end

      @amount = amount
      @task = task
      @user = user
      @transfer = Payments::BTC::InternalTransfer.new(
        user.wallet.wallet_id,
        task.wallet.wallet_id,
        amount,
      )
    end

    def submit!
      transaction = transfer.submit!
      create_user_wallet_transaction(transaction)
      update_task_balance!
    end

    private
    def create_user_wallet_transaction(transaction)
      UserWalletTransaction.create!(
        amount: amount,
        user_wallet: task.wallet.wallet_id,
        user_id: user.id,
        tx_internal_id: transaction.internal_id
      )
    end

    def wallet_handler
      Payments::BTC::WalletHandler.new
    end

    def update_task_balance!
      balance = wallet_handler.get_wallet_balance(task.wallet.wallet_id)

      if balance > 0
        task.wallet.update_attribute(:balance, balance)
        task.update_attribute(:current_fund, balance)
      end
    end
  end
end
