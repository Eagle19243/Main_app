require 'rails_helper'

RSpec.describe Payments::BTC::Base do
  let(:configuration_class) { described_class::Configuration }

  describe 'init configuration' do
    let(:supported_options) do
      %i(
        weserve_fee
        weserve_wallet_address
        coinbase_api_key
        coinbase_api_secret
      )
    end

    let(:valid_options) do
      {
        weserve_fee: "0.05",
        weserve_wallet_address: "we-serve-address",
        coinbase_api_key: "api-key",
        coinbase_api_secret: "api-secret"
      }
    end

    it "sets all possible configuration options" do
      expect { described_class.configuration }.not_to raise_error

      expect(described_class.weserve_fee.to_s).to eq(ENV['weserve_service_fee'])
      expect(described_class.weserve_fee).to be_kind_of(BigDecimal)
      expect(described_class.weserve_wallet_address).to eq(
        ENV['weserve_wallet_address']
      )
      expect(described_class.coinbase_api_key).to eq(
        ENV['coinbase_api_key']
      )
      expect(described_class.coinbase_api_secret).to eq(
        ENV['coinbase_api_secret']
      )
    end

    it "raises an error if some of the required keys are missing" do
      supported_options.each do |option|
        invalid_options = valid_options.clone
        invalid_options.delete(option)

        expect {
          configuration_class.new(invalid_options)
        }.to raise_error(ArgumentError, "missing keyword: #{option}")
      end
    end

    it "raises an error if some of the required keys are nil" do
      supported_options.each do |option|
        invalid_options = valid_options.clone
        invalid_options[option] = nil

        expect {
          configuration_class.new(invalid_options)
        }.to raise_error(ArgumentError, "#{option} cannot be empty")
      end
    end

    it "raises an error if some of the required keys are blank" do
      supported_options.each do |option|
        invalid_options = valid_options.clone
        invalid_options[option] = ""

        expect {
          configuration_class.new(invalid_options)
        }.to raise_error(ArgumentError, "#{option} cannot be empty")
      end
    end
  end
end
