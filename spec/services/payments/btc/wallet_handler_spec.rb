require 'rails_helper'

RSpec.describe Payments::BTC::WalletHandler do
  describe "#initialize" do
    it "sets an instance of client" do
      wallet_handler = described_class.new

      expect(wallet_handler.client).not_to be_nil
    end
  end

  describe 'atomic wallet actions', vcr: { cassette_name: 'coinbase/atomic_wallet_operations' } do
    it 'creates wallet' do
       wallet_handler = described_class.new
       new_wallet = wallet_handler.create_wallet('test-wallet')
       expect(new_wallet.id).to be_present
       expect(new_wallet.name).to eq 'test-wallet'
    end

    it 'gets wallet balance' do
      wallet_handler = described_class.new
      new_wallet = wallet_handler.create_wallet('test-wallet')
      expect(wallet_handler.get_wallet_balance(new_wallet["id"])).to eq 0
    end

    it 'creates address for a wallet' do
      wallet_handler = described_class.new
      new_wallet = wallet_handler.create_wallet('test-wallet')
      expect( wallet_handler.create_addess_for_wallet(new_wallet["id"])).to be_present
    end
  end

  describe "#get_wallet_transactions" do
    let(:address) { 'test-account-id' }

    context "when there is no transactions", vcr: { cassette_name: 'coinbase/wallet_transactions_empty' } do
      it "returns an empty response" do
        wallet_handler = described_class.new

        transactions = wallet_handler.get_wallet_transactions(address)
        expect(transactions.size).to eq(0)
      end
    end

    context "when there is some transactions", vcr: { cassette_name: 'coinbase/wallet_transactions_present' } do
      it "returns a response with transactions" do
        wallet_handler = described_class.new

        transactions = wallet_handler.get_wallet_transactions(address)
        expect(transactions.size).to eq(33)
      end
    end
  end
end
