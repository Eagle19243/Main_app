require 'rails_helper'

RSpec.describe Payments::BTC::ExternalTransfer do
  describe '#submit!' do
    let(:wallet_id) { "30a21ed2-4f04-57ae-9d21-becb751138f4" }
    let(:address_to) { "3Gz5Avp9KvGUyGfufnEwoqnqmsw1pgqs6V" }
    let(:amount) { 100_000 }
    let(:transfer) do
      described_class.new(wallet_id, address_to, amount)
    end

    context "when response is successful", vcr: { cassette_name: 'coinbase/send/success' } do
      it "returns transaction object" do
        transaction = transfer.submit!

        expect(transaction.internal_id).to eq("b6af30cc-5e85-5ab3-a965-8c181cc48434")
      end
    end

    context "when response cannot be parsed", vcr: { cassette_name: 'coinbase/send/unknown_response' } do
      it "returns an error" do
        expect {
          transfer.submit!
        }.to raise_error(Payments::BTC::Errors::TransferError, "Unexpected response from payment provider")
      end
    end

    context "when there is insufficient funds", vcr: { cassette_name: 'coinbase/send/insufficient_funds' } do
      it "returns an error" do
        expect {
          transfer.submit!
        }.to raise_error(Payments::BTC::Errors::TransferError, "You don't have that much.")
      end
    end

    context "when address_to is invalid", vcr: { cassette_name: 'coinbase/send/invalid_address' } do
      let(:address_to) { "ddd" }

      it "returns an error" do
        expect {
          transfer.submit!
        }.to raise_error(Payments::BTC::Errors::TransferError, "Please enter a valid email or Bitcoin address")
      end
    end

    context "when wallet id is invalid", vcr: { cassette_name: 'coinbase/send/invalid_wallet_id' } do
      let(:wallet_id) { "invalid-wallet-id" }

      it "returns an error" do
        expect {
          transfer.submit!
        }.to raise_error(Payments::BTC::Errors::TransferError, "Not found")
      end
    end
  end
end
