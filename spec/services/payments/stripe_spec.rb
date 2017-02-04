require 'rails_helper'

RSpec.describe Payments::Stripe do
  let(:stripe_helper) { StripeMock.create_test_helper }
  before { StripeMock.start }
  after { StripeMock.stop }

  subject { described_class.new(stripe_helper.generate_card_token) }


  describe '#charge!' do
    let(:description) { 'A description' }
    let(:charge) { subject.charge!(amount: amount, description: description) }

    shared_examples :unsupported_amount do
      it 'returns false' do
        expect(charge).to eq(false)
      end

      it 'populates the error message' do
        charge

        expect(subject.error).to eq("Amount #{amount} should be greater than zero")
      end
    end

    context 'when amount is less than zero' do
      let(:amount) { -20 }

      include_examples :unsupported_amount
    end

    context 'when amount is zero' do
      let(:amount) { 0 }

      include_examples :unsupported_amount
    end

    context 'when the card is declined' do
      let(:amount) { 100 }

      before do
        StripeMock.prepare_card_error(:card_declined)
      end

      it 'returns false' do
        expect(charge).to eq(false)
      end

      it 'populates the correct error message' do
        charge

        expect(subject.error).to eq('The card was declined')
      end
    end

    context 'when the card is accepted' do
      let(:amount) { 100 }

      it 'does not return false' do
        expect(charge).to be_truthy
      end

      it 'does not populate the error variable' do
        charge

        expect(subject.error).to eq(nil)
      end
    end
  end
end
