require 'rails_helper'

RSpec.describe Payments::StripeSources do
  let(:user) { FactoryGirl.create(:user, :confirmed_user) }
  let(:stripe_helper) { StripeMock.create_test_helper }
  let(:stripe_token) { stripe_helper.generate_card_token }

  before do
    StripeMock.start
  end

  after { StripeMock.stop }

  describe '#call' do
    subject { described_class.new.call(user: user) }

    context 'when stripe_customer_id is nil' do
      it 'returns an empty array' do
        expect(subject).to eq([])
      end
    end

    context 'when stripe customer exists and has cards' do
      before do
        customer = Stripe::Customer.create({
          email: user.email,
          source: stripe_token
        })

        user.update_attributes(stripe_customer_id: customer.id)
      end

      let(:stripe_helper) { StripeMock.create_test_helper }
      let(:customer_cards) do
        Stripe::Customer.retrieve(user.reload.stripe_customer_id).sources.map do |source|
          { id: source.id, last4: source.last4 }
        end
      end

      it 'returns the one card that was created' do
        expect(subject).to eq(customer_cards)
      end
    end
  end
end
