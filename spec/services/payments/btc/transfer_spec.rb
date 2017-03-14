require 'rails_helper'

RSpec.describe Payments::BTC::Transfer, vcr: { cassette_name: 'bitgo' } do
  describe '#submit!' do
    let(:wallet_id) { "test-wallet-id" }
    let(:wallet_passphrase) { "test-wallet-passphrase" }
    let(:address_to) { "test-address-to" }
    let(:amount) { 100_000 }
    let(:transfer) do
      described_class.new(wallet_id, wallet_passphrase, address_to, amount) 
    end

    context "when response is successful", vcr: { cassette_name: 'bitgo_transaction_success' } do
      it "returns transaction object" do
        transaction = transfer.submit!

        expect(transaction.status).to eq("accepted")
        expect(transaction.fee).to eq(59388)
        expect(transaction.fee_rate).to eq(163602)
        expect(transaction.tx_hex).to eq("returned-transaction-hex")
        expect(transaction.tx_hash).to eq("returned-transaction-id")
      end
    end

    context "when there is insufficient funds", vcr: { cassette_name: 'bitgo_insufficient_funds' } do
      it "returns an error" do
        expect {
          transfer.submit!
        }.to raise_error(Payments::BTC::Errors::TransferError, "Insufficient funds")
      end
    end

    context "when address_to is invalid", vcr: { cassette_name: 'bitgo_invalid_address' } do
      let(:address_to) { "ddd" }

      it "returns an error" do
        expect {
          transfer.submit!
        }.to raise_error(Payments::BTC::Errors::TransferError, "invalid bitcoin address: ddd")
      end
    end

    context "when wallet id is invalid", vcr: { cassette_name: 'bitgo_invalid_wallet_id' } do
      let(:wallet_id) { "invalid-wallet-id" }

      it "returns an error" do
        expect {
          transfer.submit!
        }.to raise_error(Payments::BTC::Errors::TransferError, "invalid wallet id")
      end
    end

    context "when wallet passphrase is invalid", vcr: { cassette_name: 'bitgo_invalid_wallet_passphrase' } do
      let(:wallet_passphrase) { "invalid-wallet-passphrase" }

      it "returns an error" do
        expect {
          transfer.submit!
        }.to raise_error(Payments::BTC::Errors::TransferError, "Unable to decrypt user keychain")
      end
    end
  end
end
