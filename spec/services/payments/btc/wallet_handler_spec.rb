require 'rails_helper'

RSpec.describe Payments::BTC::WalletHandler do
  describe "get_wallet_transactions" do
    let(:address) { '34gwmCJrA7n1L66Ufhcn7XqRNxup5ivgM5' }

    context "when there is no transactions", vcr: { cassette_name: 'bitgo_wallet_transactions_empty' } do
      it "returns an empty response" do
        wallet_handler = described_class.new

        response = wallet_handler.get_wallet_transactions(address)
        expect(response['transactions']).to eq([])
      end
    end

    context "when there is some transactions", vcr: { cassette_name: 'bitgo_wallet_transactions_present' } do
      it "returns a response with transactions" do
        wallet_handler = described_class.new
        response = wallet_handler.get_wallet_transactions(address)

        expect(response['transactions']).not_to eq([])
      end
    end
  end
end
