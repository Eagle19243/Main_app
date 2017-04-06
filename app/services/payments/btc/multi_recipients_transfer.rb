module Payments::BTC
  # This class should be used to send BTCs to multiple addresses at once.
  #
  # Class creates multiple bitcoin transactions.

  class MultiRecipientsTransfer

    attr_reader :wallet_id, :recipients

    def initialize(wallet_id, recipients)
      @wallet_id  = wallet_id
      @recipients  = recipients
    end

    # Send coins from wallet to multiple recipient's addresses
    #
    # Example:
    #
    #   transfer = Payments::BTC::MultiRecipientsTransfer.new(
    #     wallet_id,
    #     recipients
    #   )
    #   transfer.submit!
    def submit!
      transactions = []
      recipients.each do |recipient|
        begin
          log_current_parameters
          response = Payments::BTC::InternalTransfer.new( wallet_id, recipient[:address],
                                                          recipient[:amount]).submit!
          log_successfull_response(response)
          transactions << response
        rescue Coinbase::Wallet::ValidationError
          log_coinbase_error(error)
          raise Payments::BTC::Errors::TransferError, error.message
        end
      end
      transactions
    end

    private

    def logger
      @@logger ||= Logger.new("#{Rails.root}/log/#{Rails.env}_transfers.log")
    end

    def log_current_parameters
      logger.warn("#{object_id}. wallet_id #{wallet_id}, recipients: #{recipients}")
    end

    def log_successfull_response(response)
      logger.warn("#{object_id}. successful response: #{response}")
    end

    def log_failed_response(response)
      logger.error("#{object_id}. error: #{response}")
    end

    def log_coinbase_error(error)
      logger.error("#{object_id}. error: #{error.message}")
    end
  end
end
