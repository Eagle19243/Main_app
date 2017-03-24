require 'rails_helper'

RSpec.describe Payments::BTC::MultiRecipientsTransfer do
  describe '#submit!' do
    let(:wallet_id) { "test-wallet-id" }
    let(:wallet_passphrase) { "test-wallet-passphrase" }
    let(:recipients) do
      [
        { address: 'test-address-to-1', amount: 100_000 },
        { address: 'test-address-to-2', amount: 500_000 },
      ]
    end
    let(:fee) { 200_000 }
    let(:transfer) do
      described_class.new(wallet_id, wallet_passphrase, recipients, fee)
    end

    context "when response is successful", vcr: { cassette_name: 'bitgo_sendmany_success' } do
      it "returns transaction object" do
        transaction = transfer.submit!

        expect(transaction.fee).to eq(59388)
        expect(transaction.tx_hex).to eq("returned-transaction-hex")
        expect(transaction.tx_hash).to eq("returned-transaction-id")
      end
    end
  end
end
