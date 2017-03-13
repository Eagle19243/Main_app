module Payments::BTC
  class TransferFromUserWallet
    attr_reader :wallet, :amount, :address_to, :user, :transfer

    MIN_AMOUNT = 100_000 # Satoshi

    def initialize(wallet:, amount:, address_to:, user:)
      raise Payments::BTC::Errors::TransferError, "Amount can't be blank" unless amount > 0
      raise Payments::BTC::Errors::TransferError, "Amount can't be less than 0.001 BTC" unless amount > MIN_AMOUNT
      raise Payments::BTC::Errors::TransferError, "Recieve address can't be blank" unless address_to.present?

      @wallet = wallet
      @amount = amount
      @address_to = address_to.to_s.strip
      @user = user
      @transfer = Payments::BTC::Transfer.new(
        wallet.wallet_id,
        wallet.pass_phrase,
        address_to,
        amount
      )
    end

    def submit!
      user.assign_address if user.user_wallet_address.blank?

      transaction = transfer.submit!
      create_user_wallet_transaction(transaction)
    end

    private
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
