module Payments::BTC
  # Service is responsible for funding task's balance from user wallet.
  #
  # Service applies more strict validation rules and then calls
  # +Payments::BTC::FundBtcAddress+ to initiate a transfer.
  class FundTask
    MIN_AMOUNT = Task::MINIMUM_DONATION_SIZE # in satoshi

    attr_reader :amount, :task, :user, :transfer

    # Initialize +FundTask+ service which transfers coins from a user to a task
    #
    # Arguments:
    #
    #   * amount - value to send (in satoshi)
    #   * task   - task to send coins to
    #   * user   - user to charge coins from
    def initialize(amount:, task:, user:)
      raise Payments::BTC::Errors::TransferError, "Task argument is invalid" unless task.is_a?(Task)
      raise Payments::BTC::Errors::TransferError, "User argument is invalid" unless user.is_a?(User)
      raise Payments::BTC::Errors::TransferError, "User's wallet doesn't exist" unless user.wallet

      unless amount >= MIN_AMOUNT
        raise Payments::BTC::Errors::TransferError,
          "Amount can't be less than minimum allowed size (#{min_amount_in_btc} BTC)"
      end

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
    def min_amount_in_btc
      Payments::BTC::Converter.convert_satoshi_to_btc(MIN_AMOUNT)
    end

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
