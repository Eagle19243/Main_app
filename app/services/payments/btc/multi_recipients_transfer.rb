module Payments::BTC
  # This class should be used to send BTCs to multiple addresses at once.
  #
  # Class creates a bitcoin transaction with multiple inputs and outputs.
  class MultiRecipientsTransfer
    class Transacton
      attr_reader :tx_hex, :tx_hash, :fee

      def initialize(tx_hex, tx_hash, fee)
        @tx_hex = tx_hex
        @tx_hash = tx_hash
        @fee = fee
      end
    end

    attr_reader :wallet_id, :wallet_passphrase, :recipients, :fee

    def initialize(wallet_id, wallet_passphrase, recipients, fee)
      @wallet_id         = wallet_id
      @wallet_passphrase = wallet_passphrase
      @recipients        = recipients
      @fee               = fee
    end

    # Send coins from wallet to multiple recipient'ss addresses
    #
    # Example:
    #
    #   transfer = Payments::BTC::MultiRecipientsTransfer.new(
    #     wallet_id,
    #     wallet_pass,
    #     recipients
    #     fee
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
        Payments::BTC::MultiRecipientsTransfer::Transacton.new(
          response["tx"],
          response["hash"],
          response["fee"],
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
      api.send_coins_to_multiple_addresses(
        wallet_id: wallet_id,
        wallet_passphrase: wallet_passphrase,
        recipients: recipients,
        fee: fee,
        access_token: access_token
      )
    end

    def logger
      @@logger ||= Logger.new("#{Rails.root}/log/#{Rails.env}_transfers.log")
    end

    def log_current_parameters
      logger.warn("#{object_id}. wallet_id #{wallet_id}, recipients: #{recipients}, fee: #{fee}")
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
