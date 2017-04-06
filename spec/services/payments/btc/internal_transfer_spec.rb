require 'rails_helper'

RSpec.describe Payments::BTC::InternalTransfer do
  describe '#submit!' do
    let(:wallet_id) { "30a21ed2-4f04-57ae-9d21-becb751138f4" }
    let(:address_to) { "5c8e0eba-5e40-5094-88eb-d00089b62826" }
    let(:amount) { 100_000 }
    let(:transfer) do
      described_class.new(wallet_id, address_to, amount)
    end

    context "when response is successful", vcr: { cassette_name: 'coinbase/transfer/success' } do
      it "returns transaction object" do
        transaction = transfer.submit!
        expect(transaction.internal_id).to eq("0a081224-1198-5098-9076-e811f3135b13")
      end
    end

    context "when response cannot be parsed", vcr: { cassette_name: 'coinbase/transfer/unknown_response' } do
      it "returns an error" do
        expect {
          transfer.submit!
        }.to raise_error(Payments::BTC::Errors::TransferError, "Unexpected response from payment provider")
      end
    end

    context "when there is insufficient funds", vcr: { cassette_name: 'coinbase/transfer/insufficient_funds' } do
      it "returns an error" do
        expect {
          transfer.submit!
        }.to raise_error(Payments::BTC::Errors::TransferError, "Not found")
      end
    end

    context "when address_to is invalid", vcr: { cassette_name: 'coinbase/transfer/invalid_address' } do
      let(:address_to) { "ddd" }

      it "returns an error" do
        expect {
          transfer.submit!
        }.to raise_error(Payments::BTC::Errors::TransferError, "Not found")
      end
    end

    context "when wallet id is invalid", vcr: { cassette_name: 'coinbase/transfer/invalid_wallet_id' } do
      let(:wallet_id) { "invalid-wallet-id" }

      it "returns an error" do
        expect {
          transfer.submit!
        }.to raise_error(Payments::BTC::Errors::TransferError, "Not found")
      end
    end
  end
end
