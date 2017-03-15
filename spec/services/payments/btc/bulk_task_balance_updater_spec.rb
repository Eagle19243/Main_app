require 'rails_helper'

RSpec.describe Payments::BTC::BulkTaskBalanceUpdater, vcr: { cassette_name: 'bitgo_balance_requests' }  do
  let(:wallets) do
    array = []
    array << FactoryGirl.create(:wallet_address, wallet_id: 'wallet_id1')
    array << FactoryGirl.create(:wallet_address, wallet_id: 'wallet_id2')
    array << FactoryGirl.create(:wallet_address, wallet_id: 'wallet_id3')
    array << FactoryGirl.create(:wallet_address, wallet_id: 'wallet_id4')
    array << FactoryGirl.create(:wallet_address, wallet_id: 'wallet_id5')
    array
  end

  let(:expected_wallets_balance) do
    {
      1 => 470975,
      2 => 13000000,
      3 => 0,
      4 => 1804498,
      5 => 11002233
    }
  end

  let(:tasks) { FactoryGirl.create_list(:task, 5) }

  let!(:tasks_wallets_mapping) do
    mapping = {}

    tasks.each_with_index do |task, index|
      task.wallet_address = wallets[index]
      task.save
      mapping[task.id] = index + 1
    end

    mapping
  end

  it 'updates balances for tasks' do
    # balance is 0 for all tasks
    tasks.map { |task| expect(task.current_fund.to_i).to eq(0) }

    # service call
    updater = described_class.new
    updater.update_all_accepted_tasks!

    # balance has changed according to expected values
    tasks_wallets_mapping.each do |task_id, wallet_index|
      updated_task = Task.find(task_id)
      current_balance = updated_task.current_fund.to_i
      expected_balance = expected_wallets_balance[wallet_index]
      expect(current_balance).to eq(expected_balance)
    end
  end
end
