require 'rails_helper'

RSpec.describe Payments::BTC::CommissionCalculator do
  it "calculates commission" do
    subject = described_class.new(100.00)
    expect(subject.commission_in_usd).to eq(9.41)
  end

  it "calculates commission" do
    subject = described_class.new("15.00")
    expect(subject.commission_in_usd).to eq(1.65)
  end
end
