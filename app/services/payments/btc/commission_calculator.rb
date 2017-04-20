module Payments::BTC
  class CommissionCalculator
    attr_reader :usd_amount

    STRIPE_FEE            = BigDecimal.new("0.029")
    WESERVE_FEE           = BigDecimal.new("0.05")
    CONVERSION_FEE        = BigDecimal.new("0.0149")
    STRIPE_ADDITIONAL_FEE = BigDecimal.new("0.3")

    def initialize(usd_amount)
      @usd_amount = BigDecimal.new(usd_amount.to_s)
    end

    def commission_in_usd
      stripe_fee = (usd_amount * STRIPE_FEE + STRIPE_ADDITIONAL_FEE).round(2)
      usd_amount_after_stripe_fee = usd_amount - stripe_fee

      weserve_fee = (usd_amount_after_stripe_fee * WESERVE_FEE).round(2)
      usd_amount_after_weserve_fee = usd_amount_after_stripe_fee - weserve_fee

      conversion_fee = (usd_amount_after_weserve_fee * CONVERSION_FEE).round(2)
      usd_amount_after_conversion_fee = usd_amount_after_weserve_fee - conversion_fee

      (usd_amount - usd_amount_after_conversion_fee).to_f
    end
  end
end
