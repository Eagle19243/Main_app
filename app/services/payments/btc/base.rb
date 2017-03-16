class Payments::BTC::Base
  class Configuration
    attr_reader :weserve_fee, :bitgo_fee, :weserve_wallet_address,
                :bitgo_access_token, :bitgo_reserve_access_token

    def initialize(weserve_fee:, bitgo_fee:, weserve_wallet_address:, bitgo_access_token:, bitgo_reserve_access_token:)
      # validations
      raise ArgumentError, "weserve_fee cannot be empty" if weserve_fee.blank?
      raise ArgumentError, "bitgo_fee cannot be empty"   if bitgo_fee.blank?
      raise ArgumentError, "weserve_wallet_address cannot be empty" if weserve_wallet_address.blank?
      raise ArgumentError, "bitgo_access_token cannot be empty" if bitgo_access_token.blank?
      raise ArgumentError, "bitgo_reserve_access_token cannot be empty" if bitgo_reserve_access_token.blank?

      # fees configuration
      @weserve_fee = BigDecimal.new(weserve_fee)
      @bitgo_fee = BigDecimal.new(bitgo_fee)

      # system wallets configuration
      @weserve_wallet_address = weserve_wallet_address

      # bitgo access tokens configuration
      @bitgo_access_token = bitgo_access_token
      @bitgo_reserve_access_token = bitgo_reserve_access_token
    end
  end

  class << self
    delegate :weserve_fee, :bitgo_fee, :weserve_wallet_address,
             :bitgo_access_token, :bitgo_reserve_access_token, to: :configuration

    def configuration
      @configuration ||= init_configuration
    end

    private
    def init_configuration
      Configuration.new(
        weserve_fee:                ENV['weserve_service_fee'],
        bitgo_fee:                  ENV['bitgo_service_fee'],
        weserve_wallet_address:     ENV['weserve_wallet_address'],
        bitgo_access_token:         ENV['bitgo_admin_access_token'],
        bitgo_reserve_access_token: ENV['bitgo_admin_weserve_admin_access_token']
      )
    end
  end
end
