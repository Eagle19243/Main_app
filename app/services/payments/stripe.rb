class Payments::Stripe
  UnsupportedAmountType = Class.new(StandardError)

  def initialize(stripe_token)
    @stripe_token = stripe_token
    @error = nil
  end

  def charge!(amount:, description:)
    amount_in_cents =  amount_to_cents(amount)

    raise UnsupportedAmountType("Amount should be > 0 #{amount}") if amount_in_cents.zero?

    Stripe::Charge.create(
      :amount => amount_in_cents,
      :currency => "usd",
      :source => stripe_token, # obtained with Stripe.js
      :description => description
    )

  rescue Stripe::CardError => error
    # Display this to user, Probably invalid card
    @error = error
    return false
  rescue => error
    @error = 'Payment by card was unavailable, please try again'
    NewRelic::Agent.notice_error(error)
    # TO DO: Send an error message to us to handle this, Generic problem or problem with Stripe(e.g. creds, too manny requests)
    return false
  end

  attr_reader :error

  private

  attr_reader :stripe_token

  def amount_to_cents(amount)
    (amount.to_f * 100).to_i
  end
end
