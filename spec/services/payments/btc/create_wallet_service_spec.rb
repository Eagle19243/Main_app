require 'rails_helper'

RSpec.describe Payments::BTC::CreateWalletService, vcr: { cassette_name: 'coinbase/wallet_creation' } do

  describe 'Creates a user wallet' do
    let(:user) { create(:user) }

    it 'creates user wallet and assigns it receiver address' do
      expect(Wallet.count).to eq 0

      Payments::BTC::CreateWalletService.call("User", user.id)

      expect(Wallet.count).to eq 1
      expect(user.wallet.wallet_id).to be_present
      expect(user.wallet.receiver_address).to be_present
    end
  end

  describe 'Creates a task wallet' do
    let(:task) { create(:task) }

    it 'creates task wallet and assigns it receiver address' do
      expect(Wallet.count).to eq 0

      Payments::BTC::CreateWalletService.call("Task", task.id)

      expect(Wallet.count).to eq 1
      expect(task.wallet.wallet_id).to be_present
      expect(task.wallet.receiver_address).to be_blank
    end
  end
end
