class Payments::StripeSources
  def call(user:)
    stripe_customer_id = user.stripe_customer_id
    return [] unless stripe_customer_id

    customer = Stripe::Customer.retrieve(stripe_customer_id)
    customer.sources.map do |source|
      {
        id: source.id,
        last4: source.last4
      }
    end
  end
end
