module Payments::BTC
  # +Transfer+ class is responsible for calling one of the next classes:
  #
  # * InternalTransfer (to send coins from one account to another)
  # * ExternalTransfer (to send coins from account to external BTC address)
  #
  # So that +address_to+ argument for initializer may be either:
  #
  # * Any BTC Address
  # * Wallet (Account) ID
  #
  # Use +Transfer+ class only if:
  #
  # * The caller needs to send coins to a BTC Address and
  # * It's actually unknown whether this BTC Address is owned by one of our
  #   wallets or not.
  #
  # In that case, +Transfer+ class helps to save coins on fees by overwritting
  # BTC Address with corresponding Wallet (Account) ID because:
  #
  # * Internal wallet-to-wallet (account-to-account) transactions are free
  #   (but it's mandatory to provide Wallet (Account) IDs for an API call)
  #
  # and
  #
  # * External transactions to a BTC Address are require some fee
  #   (even if BTC Address is owned by another existing wallet (account))
  class Transfer
    attr_reader :wallet_id, :address_to, :amount, :send_to_email

    def initialize(wallet_id, address_to, amount, send_to_email=nil)
      @wallet_id              = wallet_id
      @address_to             = address_to
      @amount                 = amount
      @send_to_email          = send_to_email
    end

    def submit!
      tranfer_implementation.submit!
    end

    private
    def tranfer_implementation
      known_wallet = find_wallet_by_address(address_to)

      if send_to_email
        CoinbaseInternalTransfer.new(
          wallet_id,
          address_to,
          amount
        )
      elsif known_wallet
        InternalTransfer.new(
          wallet_id,
          known_wallet.wallet_id,
          amount
        )
      else
        ExternalTransfer.new(
          wallet_id,
          address_to,
          amount
        )
      end
    end

    def find_wallet_by_address(address)
      Wallet.find_by(receiver_address: address)
    end
  end
end
