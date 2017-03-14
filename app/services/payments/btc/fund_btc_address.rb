module Payments::BTC
  # Service is responsible for funding any bitcoin address from user wallet.
  #
  # For transfers to task wallet see +Payments::BTC::FundTask+
  class FundBtcAddress
    attr_reader :amount, :address_to, :user, :transfer

    MIN_AMOUNT = 100_000 # Satoshi

    def initialize(amount:, address_to:, user:)
      raise Payments::BTC::Errors::TransferError, "Amount can't be blank" unless amount > 0
      raise Payments::BTC::Errors::TransferError, "Amount can't be less than 0.001 BTC" unless amount >= MIN_AMOUNT
      raise Payments::BTC::Errors::TransferError, "Recieve address can't be blank" unless address_to.present?
      raise Payments::BTC::Errors::TransferError, "User's wallet doesn't exist" unless user.user_wallet_address

      @amount = amount
      @address_to = address_to.to_s.strip
      @user = user
      @transfer = Payments::BTC::Transfer.new(
        user.user_wallet_address.wallet_id,
        user.user_wallet_address.pass_phrase,
        address_to,
        amount
      )
    end

    def submit!
      transaction = transfer.submit!
      create_user_wallet_transaction(transaction)
      mark_transfer_as_successful!
    end

    def successful?
      @success == true
    end

    private
    def mark_transfer_as_successful!
      @success = true
    end

    def create_user_wallet_transaction(transaction)
      UserWalletTransaction.create!(
        amount: amount,
        user_wallet: address_to,
        user_id: user.id,
        tx_hex: transaction.tx_hex,
        tx_id:  transaction.tx_hash
      )
    end
  end
end
