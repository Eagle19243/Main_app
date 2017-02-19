# frozen_string_literal: true
class Payments::Stripe
  UnsupportedAmountType = Class.new(StandardError)

  def initialize(stripe_token: nil, user: nil, card_id: nil, persist_card: false)
    if stripe_token.present?
      @stripe_token = stripe_token
    elsif user.present? && card_id.present?
      @card_id = card_id
    else
      raise(ArgumentError, 'You should provide either stripe token with/without a user or the preferred card_id with the user')
    end

    @user = user
    @error = nil
    @persist_card = persist_card
  end

  def charge!(amount:, description:)
    @amount_in_cents = amount_to_cents(amount)
    @description = description
    raise(UnsupportedAmountType, "Amount #{amount} should be greater than zero") unless amount_in_cents > 0

    choose_payment_method

  rescue Stripe::CardError => error
    # Display this to user, Probably invalid card
    @error = error.message
    return false
  rescue UnsupportedAmountType => error
    @error = error.message
    return false
  rescue => error
    @error = 'Payment by card was unavailable, please try again'

    # handle error internal and notify exception services
    NewRelic::Agent.notice_error(error)
    Rollbar.error(error)
    # Send an error message to us to handle this,
    # Generic problem or problem with Stripe(e.g. creds, too manny requests)
    return false
  end

  attr_reader :error, :stripe_response

  private

  attr_reader :stripe_token, :user, :card_id, :persist_card, :amount_in_cents, :description

  def choose_payment_method
    stripe_customer_id = user.try(:stripe_customer_id)

    if card_id.present?
      charge_card(card_id)
    elsif persist_card && stripe_customer_id.present?
      assign_and_charge_new_card
    elsif persist_card && stripe_customer_id.nil?
      create_and_charge_new_customer
    else
      # single transaction without saving card
      charge_card_without_saving
    end
  end

  def charge_card_without_saving
    options = {
      amount: amount_in_cents,
      currency: 'usd',
      source: stripe_token, # obtained with Stripe.js
      description: description
    }

    charge_amount!(options)
  end

  def create_and_charge_new_customer
    customer = Stripe::Customer.create(email: user.email, source: stripe_token)

    user.update_attributes(stripe_customer_id: customer.id)

    options = {
      amount: amount_in_cents,
      currency: 'usd',
      customer: customer.id,
      description: description
    }

    charge_amount!(options)
  end

  def charge_card(card_id)
    options = {
      amount: amount_in_cents,
      currency: 'usd',
      customer: user.stripe_customer_id,
      card: card_id,
      description: description
    }

    charge_amount!(options)
  end

  def assign_and_charge_new_card
    customer = Stripe::Customer.retrieve(user.stripe_customer_id)
    card = customer.sources.create(source: stripe_token)

    charge_card(card.id)
  end

  def charge_amount!(options)
    @stripe_response = Stripe::Charge.create(options)
  end

  def amount_to_cents(amount)
    (amount.to_f * 100).to_i
  end
end
