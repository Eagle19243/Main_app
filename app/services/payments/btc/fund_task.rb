module Payments::BTC
  # Service is responsible for funding task's balance from user wallet.
  #
  # Service applies more strict validation rules and then calls
  # +Payments::BTC::FundBtcAddress+ to initiate a transfer.
  class FundTask
    MIN_AMOUNT = Task::MINIMUM_DONATION_SIZE

    attr_reader :fund_btc_address

    def initialize(amount:, task:, user:)
      raise Payments::BTC::Errors::TransferError, "Task argument is invalid" unless task.is_a?(Task)
      raise Payments::BTC::Errors::TransferError, "Amount can't be less than minimum allowed size" unless amount >= MIN_AMOUNT

      Payments::BTC::CreateTaskWalletService.call(task.id) unless task.wallet_address.present?

      @fund_btc_address = Payments::BTC::FundBtcAddress.new(
        amount: amount,
        address_to: task.wallet_address.sender_address,
        user: user
      )
    end

    def submit!
      fund_btc_address.submit!
    end

    def successful?
      fund_btc_address.successful?
    end
  end
end
