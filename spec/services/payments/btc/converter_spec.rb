require 'rails_helper'

RSpec.describe Payments::BTC::Converter do

  before do
    allow(Payments::BTC::Converter).to receive(:get_current_btc_rate).and_return(1228.96)
  end

  describe 'converts usd to btc' do
    
    it 'returns 0 btc for 0 usd or blank amount' do
      expect(Payments::BTC::Converter.convert_usd_to_btc(0)).to eq 0
      expect(Payments::BTC::Converter.convert_usd_to_btc("")).to eq 0
    end

    it 'returns amount of btc for usd' do
      expect(Payments::BTC::Converter.convert_usd_to_btc(560)).to eq 0.4556698346569457
    end

  end

  describe 'converts usd to satoshi' do

    it 'returns 0 satoshi for 0 usd or blank amount' do
      expect(Payments::BTC::Converter.convert_usd_to_satoshi(0)).to eq 0
      expect(Payments::BTC::Converter.convert_usd_to_satoshi("")).to eq 0
    end

    it 'retuns satoshi amount from usd' do
      expect(Payments::BTC::Converter.convert_usd_to_satoshi(560)).to eq 45566983
    end

  end

  describe 'converts btc to usd' do

    it 'returns 0 usd for 0 or blank amount of btc' do
      expect(Payments::BTC::Converter.convert_btc_to_usd(0)).to eq 0
      expect(Payments::BTC::Converter.convert_btc_to_usd("")).to eq 0
    end
    
    it 'returnes amount of usd for btc' do
      expect(Payments::BTC::Converter.convert_btc_to_usd(0.4556698346569457)).to eq 560
    end

  end

  describe 'converts btc to satoshi' do

    it 'returns 0 satoshi for 0 or blank amount of btc' do
      expect(Payments::BTC::Converter.convert_btc_to_satoshi(0)).to eq 0
      expect(Payments::BTC::Converter.convert_btc_to_satoshi("")).to eq 0
    end
    
    it 'returnes amount of satoshi for btc' do
      expect(Payments::BTC::Converter.convert_btc_to_satoshi(3)).to eq 300000000
    end

  end

  describe 'converts satoshi to btc' do

    it 'returns 0 btc for 0 or blank amount of satoshis' do
      expect(Payments::BTC::Converter.convert_satoshi_to_btc(0)).to eq 0
      expect(Payments::BTC::Converter.convert_satoshi_to_btc("")).to eq 0
    end
    
    it 'returnes amount of btc for satoshis' do
      expect(Payments::BTC::Converter.convert_satoshi_to_btc(300000000)).to eq 3
    end

  end

  describe 'converts satoshi to usd' do

    it 'returns 0 usd for 0 or blank amount of satoshis' do
      expect(Payments::BTC::Converter.convert_satoshi_to_usd(0)).to eq 0
      expect(Payments::BTC::Converter.convert_satoshi_to_usd("")).to eq 0
    end
    
    it 'returnes amount of satoshi for usd' do
      expect(Payments::BTC::Converter.convert_satoshi_to_usd(45566983)).to eq 559.9999942768001
    end

  end


end
