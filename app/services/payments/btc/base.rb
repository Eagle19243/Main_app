class Payments::BTC::Base
  class Configuration
    attr_reader :weserve_fee,             # commission which weserve takes
                :weserve_wallet_address,  # wallet address used to accept weserve commission
                :coinbase_api_key,        # coinbase api key
                :coinbase_api_secret      # coinbase api secret

    def initialize(weserve_fee:, weserve_wallet_address:, coinbase_api_key:, coinbase_api_secret:)
      # validations
      raise ArgumentError, "weserve_fee cannot be empty" if weserve_fee.blank?
      raise ArgumentError, "weserve_wallet_address cannot be empty" if weserve_wallet_address.blank?
      raise ArgumentError, "coinbase_api_key cannot be empty" if coinbase_api_key.blank?
      raise ArgumentError, "coinbase_api_secret cannot be empty" if coinbase_api_secret.blank?

      # fees configuration
      @weserve_fee = BigDecimal.new(weserve_fee)

      # system wallets configuration
      @weserve_wallet_address = weserve_wallet_address

      # coinbase access tokens configuration
      @coinbase_api_key = coinbase_api_key
      @coinbase_api_secret = coinbase_api_secret
    end
  end

  class << self
    delegate :weserve_fee, :weserve_wallet_address,
             :coinbase_api_key, :coinbase_api_secret, to: :configuration

    def configuration
      @configuration ||= init_configuration
    end

    private
    def init_configuration
      Configuration.new(
        weserve_fee:            ENV['weserve_service_fee'],
        weserve_wallet_address: ENV['weserve_wallet_address'],
        coinbase_api_key:       ENV['coinbase_api_key'],
        coinbase_api_secret:    ENV['coinbase_api_secret']
      )
    end
  end
end
