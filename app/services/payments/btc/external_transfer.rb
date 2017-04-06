module Payments::BTC
  # +ExternalTransfer+ class is responsible for transfers from `wallet` to any
  # external bitcoin address.
  #
  # Important:
  #
  #   * Fees may be applied when using this class.
  #
  # Usage:
  #
  #   transfer = ExternalTransfer.new(
  #     wallet_id,
  #     address,
  #     amount
  #   )
  #   transfer.submit!
  class ExternalTransfer < BaseTransfer
    # +ExternalTransfer+ class initialization.
    #
    # Arguments:
    #
    #   * wallet_id [String] id of wallet to send coins from (account)
    #   * address [String] any bitcoin address to send coins to
    #   * amount [Integer] amount in satoshi
    def initialize(wallet_id, address_to, amount)
      super
    end

    private
    def api_request
      account.send(
        to: address_to,
        amount: amount_in_btc,
        currency: "BTC",
        description: description,
        expand: 'all'
      )
    end

    def description
      "External transfer from #{wallet_id} to #{address_to}"
    end
  end
end
