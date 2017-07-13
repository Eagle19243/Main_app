module Payments::BTC
  # +CoinbaseInternalTransfer+ class is responsible for transfers from `wallet` to users 
  # Coinbase account via his email.
  #
  # Important:
  #
  #   * Fees are not applied because transfers to email within Coinbase are free.
  #
  # Usage:
  #
  #   transfer = CoinbaseInternalTransfer.new(
  #     wallet_id,
  #     address,
  #     amount
  #   )
  #   transfer.submit!
  class CoinbaseInternalTransfer < BaseTransfer
    # +CoinbaseInternalTransfer+ class initialization.
    #
    # Arguments:
    #
    #   * wallet_id [String] id of wallet to send coins from (account)
    #   * address [String] email addres (account) to send coins to
    #   * amount [Integer] amount in satoshi
    #
    def initialize(wallet_id, address_to, amount)
      super
    end

    private

    def api_request
      account.send(
        to: address_to,
        amount: amount_in_btc,
        currency: "BTC",
        description: description
      )
    end

    def description
      "Coinbase Internal send from #{wallet_id} to #{address_to}"
    end
  end
end
