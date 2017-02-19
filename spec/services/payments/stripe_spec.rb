require 'rails_helper'

RSpec.describe Payments::Stripe do
  let(:stripe_helper) { StripeMock.create_test_helper }
  let(:user) { FactoryGirl.create(:user, :confirmed_user) }
  after { StripeMock.stop }

  before do
    StripeMock.start

    # This is needed because on the creation of a user we call bitgo. This might have to be refactored and removed from the user model
    allow_any_instance_of(User).to receive(:assign_address).and_return(UserWalletAddress.create(sender_address: nil))
  end


  describe '.new' do
    let(:args) { {} }
    subject { described_class.new(args) }

    shared_context :no_error do
      it 'does not raises an error' do
        expect {
          subject
        }.not_to raise_error
      end
    end

    context 'when a stripe token is passed as argument' do
      let(:args) { { stripe_token: stripe_helper.generate_card_token } }

      include_examples :no_error
    end

    context 'when a user and a card_id is passed as arguments' do
      let(:args) { { stripe_token: stripe_helper.generate_card_token } }

      include_examples :no_error
    end

    context 'when not enough arguments are passed' do
      let(:args) { { card_id: stripe_helper.generate_card_token } }

      it 'raises an error' do
        expect {
          subject
        }.to raise_error(ArgumentError, 'You should provide either stripe token with/without a user or the preferred card_id with the user')
      end
    end
  end


  describe '#charge!' do
    let(:charge) { subject.charge!(amount: amount, description: description) }
    let(:description) { 'A description' }
    let(:amount) { 100 }

    shared_examples :successful_transaction do
      it 'populates the stripe_response variable' do
        charge

        expect(subject.stripe_response).to be_an_instance_of(Stripe::Charge)
      end

      it 'does not populate the error variable' do
        charge

        expect(subject.error).to eq(nil)
      end

      it 'charges the customer' do
        expect(Stripe::Charge).to receive(:create).and_call_original

        charge
      end
    end


    shared_examples :unsuccessful_transaction do
      it 'returns false' do
        expect(charge).to eq(false)
      end

      it 'populates the correct error message' do
        charge

        expect(subject.error).to eq('The card was declined')
      end
    end

    context 'when stripe token is passed' do
      context 'when persist_card is false' do
        subject { described_class.new(stripe_token: stripe_helper.generate_card_token) }


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

          include_examples :unsuccessful_transaction
        end

        context 'when the card is accepted' do
          let(:amount) { 100 }

          include_examples :successful_transaction
        end
      end

      context 'when persist_card is true' do
        let(:stripe_token) { stripe_helper.generate_card_token }
        subject { described_class.new(stripe_token: stripe_token, user: user, persist_card: true) }

        context 'when stripe customer id exists already' do
          before do
            customer = Stripe::Customer.create({
              email: user.email,
              source: stripe_token
            })

            user.update_attributes(stripe_customer_id: customer.id)
          end

          context 'when the card is declined' do
            before do
              StripeMock.prepare_card_error(:card_declined)
            end

            include_examples :unsuccessful_transaction
          end

          context 'when the card is accepted' do
            it 'creates a new card' do
              expect_any_instance_of(Stripe::ListObject).to receive(:create).with(source: stripe_token).and_call_original

              charge
            end

            include_examples :successful_transaction
          end
        end

        context 'when stripe_customer_id does not exist' do
          context 'when the card is accepted' do
            it 'creates a new stripe_customer_id and saves it in the database' do
              expect(user.stripe_customer_id).to eq(nil)

              charge
              expect(user.reload.stripe_customer_id).not_to eq(nil)
            end

            include_examples :successful_transaction
          end

          context 'when the card is declined' do
            before do
              StripeMock.prepare_card_error(:card_declined)
            end

            include_examples :unsuccessful_transaction
          end
        end
      end
    end

    context 'when card_id is passed' do
      subject { described_class.new(card_id: @card_id, user: user) }

      let(:stripe_token) { stripe_helper.generate_card_token }
      before do
        customer = Stripe::Customer.create({
          email: user.email,
          source: stripe_token
        })

        user.update_attributes(stripe_customer_id: customer.id)

        @card_id = customer.sources.first.id
      end

      context 'when the card is accepted' do
        include_examples :successful_transaction
      end

      context 'when the card is declined' do
        before do
          StripeMock.prepare_card_error(:card_declined)
        end

        include_examples :unsuccessful_transaction
      end
    end
  end
end
