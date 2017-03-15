class Payments::BTC::Converter

  class << self

    def convert_usd_to_btc(usd)
      usd.blank? ? 0.0 : (usd.to_f / current_btc_rate.to_f)
    end

    def convert_usd_to_satoshi(usd)
      usd.blank? ? 0.0 : convert_btc_to_satoshi( convert_usd_to_btc(usd) )
    end

    def convert_btc_to_usd(btc)
      btc.blank? ? 0.0 : ( btc.to_f * current_btc_rate.to_f )
    end

    def convert_btc_to_satoshi(btc)
      btc.blank? ? 0.0 : (btc.to_f * (10 ** 8)).to_i
    end

    def convert_satoshi_to_btc(satoshi)
      satoshi.blank? ? 0.0 : satoshi.to_f/10**8.to_f
    end

    def convert_satoshi_to_usd(satoshi)
      satoshi.blank? ? 0.0 : convert_btc_to_usd( convert_satoshi_to_btc(satoshi) )
    end

    def current_btc_rate
      BtcExchangeRate.last.rate
    end

  end


end
