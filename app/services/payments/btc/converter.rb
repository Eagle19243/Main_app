class Payments::BTC::Converter

  class << self

    def convert_usd_to_btc(usd)
      usd.blank? ? 0.0 : (usd.to_f / get_current_btc_rate.to_f)
    end

    def convert_usd_to_satoshi(usd)
      usd.blank? ? 0.0 : convert_btc_to_satoshi( convert_usd_to_btc(usd) )
    end

    def convert_btc_to_usd(btc)
      btc.blank? ? 0.0 : ( btc.to_f * get_current_btc_rate.to_f )
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

    def get_current_btc_rate
      begin
        response ||= RestClient.get 'https://www.bitstamp.net/api/ticker/'
        btc=JSON.parse(response)['last'] rescue 0.0
        btc.to_f
      rescue
        "error while converting usd to btd and then to satoshi"
      end
    end

  end


end
