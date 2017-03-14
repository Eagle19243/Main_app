require 'rails_helper'

RSpec.describe Payments::BTC::FeeCalculator do
  let(:rate_per_byte) { described_class::RATE_PER_BYTE }

  describe '#estimate' do
    it "calculates transaction fee for inputs=1 outputs=2" do
      fee = described_class.estimate(1, 2)
      expect(fee).to eq(372 * rate_per_byte)
    end

    it "calculates transaction fee for inputs=2 outputs=2" do
      fee = described_class.estimate(2, 2)
      expect(fee).to eq(666 * rate_per_byte)
    end

    it "calculates transaction fee for inputs=5 outputs=2" do
      fee = described_class.estimate(5, 2)
      expect(fee).to eq(1548 * rate_per_byte)
    end
  end
end
