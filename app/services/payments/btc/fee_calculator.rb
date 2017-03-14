class Payments::BTC::FeeCalculator
  RATE_PER_BYTE = 180 # Rate in satoshis

  class << self
    def estimate(num_inputs, num_outputs)
      transaction_size_in_bytes(num_inputs, num_outputs) * RATE_PER_BYTE
    end

    private
    # Usual transaction size formula is:
    #
    #   inputs * 180 + outputs * 34 + 10 + inputs
    #
    # But formula is true only for inputs signed with single signature.
    #
    # So that, we add 113 as overhead for every input because our inputs
    # contain multiple signatures (2-of-3 multisig)
    def transaction_size_in_bytes(num_inputs, num_outputs)
      num_inputs * (180 + 113) + num_outputs * 34 + 10 + num_inputs
    end
  end
end
