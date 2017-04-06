require 'coinbase/wallet'

module Payments::BTC
  # +BaseTransfer+ class is a superclass for implementation of child
  # +Transfer+ classes.
  #
  # The idea is to re-use:
  #
  # * logging
  # * exception handling
  # * coinbase client/account methods
  #
  # in child transfer classes
  class BaseTransfer
    class Transaction
      attr_reader :internal_id

      def initialize(internal_id)
        @internal_id = internal_id
      end
    end

    attr_reader :wallet_id, :address_to, :amount

    def initialize(wallet_id, address_to, amount)
      @wallet_id         = wallet_id
      @address_to        = address_to
      @amount            = amount
    end

    def submit!
      log_current_parameters

      response = api_request

      if response["id"]
        log_successfull_response(response)

        Payments::BTC::BaseTransfer::Transaction.new(response["id"])
      else
        log_failed_response(response)

        raise Payments::BTC::Errors::TransferError,
          "Unexpected response from payment provider"
      end
    rescue StandardError => error
      log_coinbase_error(error)
      raise Payments::BTC::Errors::TransferError, error.message
    end

    def api_request
      raise NotImplementedError
    end

    private
    def amount_in_btc
      Payments::BTC::Converter.convert_satoshi_to_btc(amount).to_s
    end

    def client
      Coinbase::Wallet::Client.new(
        api_key:    Payments::BTC::Base.coinbase_api_key,
        api_secret: Payments::BTC::Base.coinbase_api_secret
      )
    end

    def account
      client.account(wallet_id)
    end

    def logger
      @@logger ||= Logger.new("#{Rails.root}/log/#{Rails.env}_transfers.log")
    end

    def log_current_parameters
      logger.warn("#{object_id}. wallet_id #{wallet_id}, address_to: #{address_to}, amount: #{amount}")
    end

    def log_successfull_response(response)
      logger.warn("#{object_id}. successful response: #{response.to_s}")
    end

    def log_failed_response(response)
      logger.error("#{object_id}. error: #{response.to_s}")
    end

    def log_coinbase_error(error)
      logger.error("#{object_id}. error: #{error.message}")
    end
  end
end
