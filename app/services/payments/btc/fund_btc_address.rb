module Payments::BTC
  # Service is responsible for funding any bitcoin address from user wallet.
  #
  # For transfers to task wallet see +Payments::BTC::FundTask+
  class FundBtcAddress
    attr_reader :amount, :address_to, :user, :transfer

    MIN_AMOUNT = 100_000 # Satoshi

    def initialize(amount:, address_to:, user:, send_to_email: nil)
      raise Payments::BTC::Errors::TransferError, "User argument is invalid" unless user.is_a?(User)
      raise Payments::BTC::Errors::TransferError, "User's wallet doesn't exist" unless user.wallet
      raise Payments::BTC::Errors::TransferError, "Amount can't be blank" unless amount > 0
      raise Payments::BTC::Errors::TransferError, "Amount can't be less than 0.001 BTC" unless amount >= MIN_AMOUNT
      raise Payments::BTC::Errors::TransferError, "Recieve address can't be blank" unless address_to.present?

      @amount = amount
      @address_to = address_to.to_s.strip
      @user = user
      @transfer = Payments::BTC::Transfer.new(
        user.wallet.wallet_id,
        address_to,
        amount,
        send_to_email
      )
    end

    def submit!
      transaction = transfer.submit!
      create_user_wallet_transaction(transaction)
    end

    private
    def create_user_wallet_transaction(transaction)
      UserWalletTransaction.create!(
        amount: amount,
        user_wallet: address_to,
        user_id: user.id,
        tx_internal_id: transaction.internal_id
      )
    end
  end
end
