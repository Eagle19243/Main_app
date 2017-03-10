module Payments::BTC
  class Transfer
    class Transacton
      attr_reader :status, :tx_hex, :tx_hash, :fee, :fee_rate

      def initialize(status, tx_hex, tx_hash, fee, fee_rate)
        @status = status
        @tx_hex = tx_hex
        @tx_hash = tx_hash
        @fee = fee
        @fee_rate = fee_rate
      end
    end

    attr_reader :wallet_id, :wallet_passphrase, :address_to, :amount

    def initialize(wallet_id, wallet_passphrase, address_to, amount)
      @wallet_id         = wallet_id
      @wallet_passphrase = wallet_passphrase
      @address_to        = address_to
      @amount            = amount
    end

    # Send coins from wallet to any bitcoin address
    #
    # Example:
    #
    #   transfer = Payments::BTC::Transfer.new(
    #     wallet_id,
    #     wallet_pass,
    #     address_to,
    #     amount
    #   )
    #   transfer.submit!
    def submit!
      log_current_parameters

      response = call_bitgo_api!

      if response["message"].present?
        log_failed_response(response)
        raise Payments::BTC::Errors::TransferError, response["message"]
      else
        log_successfull_response(response)
        Payments::BTC::Transfer::Transacton.new(
          response["status"],
          response["tx"],
          response["hash"],
          response["fee"],
          response["feeRate"]
        )
      end
    rescue Bitgo::V1::ApiError => error
      log_bitgo_error(error)
      raise Payments::BTC::Errors::TransferError, error.message
    end

    private
    def api
      Bitgo::V1::Api.new
    end

    def access_token
      Payments::BTC::Base.bitgo_access_token
    end

    def call_bitgo_api!
      api.send_coins_to_address(
        wallet_id: wallet_id,
        address: address_to,
        amount: amount ,
        wallet_passphrase: wallet_passphrase,
        access_token: access_token
      )
    end

    def logger
      @@logger ||= Logger.new("#{Rails.root}/log/#{Rails.env}_transfers.log")
    end

    def log_current_parameters
      logger.warn("#{object_id}. wallet_id #{wallet_id}, address_to: #{address_to}, amount: #{amount}")
    end

    def log_successfull_response(response)
      logger.warn("#{object_id}. successful response: #{response}")
    end

    def log_failed_response(response)
      logger.error("#{object_id}. error: #{response}")
    end

    def log_bitgo_error(error)
      logger.error("#{object_id}. error: #{error.message}")
    end
  end
end
