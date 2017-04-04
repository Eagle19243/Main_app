require 'rails_helper'

RSpec.describe Payments::BTC::Transfer do
  describe '#submit!' do
    let(:wallet_id) { "30a21ed2-4f04-57ae-9d21-becb751138f4" }
    let(:amount) { 100_000 }
    let(:transfer) do
      described_class.new(wallet_id, address_to, amount) 
    end

    context "when address_to is not attached to any existing wallets" do
      let(:address_to) { "uknown-btc-address" }

      it "calls ExternalTransfer" do
        # Verify that ExternalTransfer is initialized with correct arguments:
        expect(Payments::BTC::ExternalTransfer).to receive(:new).with(
          wallet_id,
          address_to,
          amount
        ).and_call_original

        # Verify that ExternalTransfer calls submit!
        expect_any_instance_of(Payments::BTC::ExternalTransfer).to receive(:submit!).and_return(true)

        transfer.submit!
      end
    end

    context "when address_to is attached to existing wallet" do
      let!(:address_to) { "known-btc-address" }
      let!(:wallet) { create(:wallet, receiver_address: address_to) }

      it "calls InternalTransfer" do
        # Verify that InternalTransfer is initialized with correct arguments:
        expect(Payments::BTC::InternalTransfer).to receive(:new).with(
          wallet_id,
          wallet.wallet_id,
          amount
        ).and_call_original

        # Verify that InternalTransfer calls submit!
        expect_any_instance_of(Payments::BTC::InternalTransfer).to receive(:submit!).and_return(true)

        transfer.submit!
      end
    end
  end
end
