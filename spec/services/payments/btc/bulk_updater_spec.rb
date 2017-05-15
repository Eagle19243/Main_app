require 'rails_helper'

RSpec.describe Payments::BTC::BulkUpdater, vcr: { cassette_name: 'coinbase/bulk_updates' }  do
  let(:user) { create(:user) }
  let(:task) { create(:task) }
  let(:bulk_updater) { Payments::BTC::BulkUpdater.new }

  before do
    Payments::BTC::CreateWalletService.call("User", user.id)
    Payments::BTC::CreateWalletService.call("Task", task.id)
    user.wallet.update(balance: 2)
    task.wallet.update(balance: 5)
  end

  it 'updates balances for tasks' do

    expect(user.wallet.balance).to eq 2
    expect(task.wallet.balance).to eq 5
    expect(task.wallet.balance).to eq 5

    bulk_updater.update_all_wallets_balance!
    user.reload
    task.reload
    expect(user.wallet.balance).to eq 0
    expect(task.wallet.balance).to eq 0
    expect(task.wallet.balance).to eq 0
  end

  it 'does not update balance for the completed task' do
    task.update(state: 'completed')
    expect(task.wallet.balance).to eq 5
    expect(task.current_fund).to eq 5

    bulk_updater.update_all_wallets_balance!

    expect(task.current_fund).to eq 5
    expect(task.wallet.balance).to eq 5
  end

  it 'updates receiving address for wallets' do
    old_user_wallet_address = user.wallet.receiver_address
    expect(task.wallet.receiver_address).to eq ''

    bulk_updater.update_all_wallets_receiver_address!
    user.reload
    task.reload

    expect(user.wallet.receiver_address).not_to eq old_user_wallet_address
    expect(task.wallet.receiver_address).to eq ''
  end

end
