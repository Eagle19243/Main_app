require 'rails_helper'

RSpec.describe Payments::BTC::Base do
  describe '#configure' do
    let(:supported_options) do
      %i(
        weserve_fee
        bitgo_fee
        weserve_wallet_address
        bitgo_access_token
        bitgo_reserve_access_token
      )
    end

    let(:valid_options) do
      {
        weserve_fee: "0.05",
        bitgo_fee:   "0.001",
        weserve_wallet_address: "we-serve-address",
        bitgo_access_token: "access-token",
        bitgo_reserve_access_token: "reserve-access-token"
      }
    end

    it "sets all possible configuration options" do
      expect { described_class.configure(valid_options) }.not_to raise_error

      expect(described_class.weserve_fee).to eq(0.05)
      expect(described_class.weserve_fee).to be_kind_of(BigDecimal)
      expect(described_class.bitgo_fee).to eq(0.001)
      expect(described_class.bitgo_fee).to be_kind_of(BigDecimal)
      expect(described_class.weserve_wallet_address).to eq("we-serve-address")
      expect(described_class.bitgo_access_token).to eq("access-token")
      expect(described_class.bitgo_reserve_access_token).to eq(
        "reserve-access-token"
      )
    end

    it "raises an error if some of the required keys are missing" do
      supported_options.each do |option|
        invalid_options = valid_options.clone
        invalid_options.delete(option)

        expect {
          described_class.configure(invalid_options)
        }.to raise_error(ArgumentError, "missing keyword: #{option}")
      end
    end

    it "raises an error if some of the required keys are nil" do
      supported_options.each do |option|
        invalid_options = valid_options.clone
        invalid_options[option] = nil

        expect {
          described_class.configure(invalid_options)
        }.to raise_error(ArgumentError, "#{option} cannot be empty")
      end
    end

    it "raises an error if some of the required keys are blank" do
      supported_options.each do |option|
        invalid_options = valid_options.clone
        invalid_options[option] = ""

        expect {
          described_class.configure(invalid_options)
        }.to raise_error(ArgumentError, "#{option} cannot be empty")
      end
    end
  end
end
