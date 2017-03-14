require 'rails_helper'

describe ApplicationHelper do

  before do
    allow(Payments::BTC::Converter).to receive(:get_current_btc_rate).and_return(1228.96)
  end

  it 'shows btc in 4 decimals' do
    expect(btc_balance(3.452678)).to eq 3.4527
  end

  it 'shows satoshi balance in btc with 4 decimals' do
    expect(satoshi_balance_in_btc(2334643)).to eq 0.0233
  end

  it 'shows satoshi balance in usd with 3 decimals' do
    expect(satoshi_balance_in_usd(2334643)).to eq 28.692
  end

end
