require 'coinbase/wallet'

module Payments::BTC
  class WalletHandler
    attr_reader :client

    def initialize
      @client = Coinbase::Wallet::Client.new(
        api_key:    Payments::BTC::Base.coinbase_api_key,
        api_secret: Payments::BTC::Base.coinbase_api_secret
      )
    end

    def create_wallet(wallet_name)
      client.create_account(name: wallet_name)
    end

    def get_wallet(wallet_id)
      client.account(wallet_id)
    end

    def create_addess_for_wallet(wallet_id)
      get_wallet(wallet_id).create_address["address"]
    end

    def get_wallet_balance(wallet_id)
      btc_amount = get_wallet(wallet_id).balance.amount
      Converter.convert_btc_to_satoshi(btc_amount)
    end

    def get_wallet_transactions(wallet_id)
      transactions = get_wallet(wallet_id).transactions(limit: 100, order: :desc)

      transactions.map do |transaction_hash|
        mapper = Mappers::WalletTransaction.new(transaction_hash)
        mapper.build_wallet_transaction
      end
    end

  end
end
