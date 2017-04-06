module Payments::BTC
  # +InternalTransfer+ class is responsible for transfers from `wallet` to any
  # other +wallet+ withing the same +account+.
  #
  # Important:
  #
  #   * Fees are not applied because internal transfers are free.
  #
  # Usage:
  #
  #   transfer = InternalTransfer.new(
  #     wallet_id,
  #     address,
  #     amount
  #   )
  #   transfer.submit!
  class InternalTransfer < BaseTransfer
    # +InternalTransfer+ class initialization.
    #
    # Arguments:
    #
    #   * wallet_id [String] id of wallet to send coins from (account)
    #   * address [String] id of wallet (account) to send coins to
    #   * amount [Integer] amount in satoshi
    #
    def initialize(wallet_id, address_to, amount)
      super
    end

    private

    def api_request
      account.transfer(
        to: address_to,
        amount: amount_in_btc,
        currency: "BTC",
        description: description,
        expand: 'all'
      )
    end

    def description
      "Internal transfer from #{wallet_id} to #{address_to}"
    end
  end
end
