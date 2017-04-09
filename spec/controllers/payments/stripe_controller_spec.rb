require 'rails_helper'

RSpec.describe Payments::StripeController do
  render_views

  let(:task) { FactoryGirl.create(:task, :with_associations, :with_wallet) }
  let(:user) { task.user }
  let(:project) { task.project }

  before do
    stub_env('reserve_wallet_id', '30a21ed2-4f04-57ae-9d21-becb751138f4')
  end

  describe '#new' do
    subject(:make_request) { get(:new, id: task.id, project_id: project.id) }

    context 'when the user is not signed' do
      it 'redirects to sign in' do
        make_request
        expect(response).to redirect_to(new_user_session_url)
      end
    end

    context 'when user is signed in' do
      before do
        sign_in(user)
      end

      it 'renders the new page' do
        make_request
        expect(response).to render_template(:new)
      end

      it 'assign the task instance variable' do
        make_request
        expect(assigns(:task)).to eq(task)
      end
    end
  end

  describe '#create' do
    subject(:make_request) { post :create, params }
    let(:stripe_helper) { StripeMock.create_test_helper }

    before { StripeMock.start }
    after { StripeMock.stop }

    context 'when the user is not signed' do
      let(:params) { { stripeToken: stripe_helper.generate_card_token, amount: '220.20', project_id: project.id, id: task.id, format: 'json' } }

      it 'returns an error' do
        make_request
        expect(response.body).to include_json(
          error: "You need to sign in or sign up before continuing."
        )
      end
    end

    context 'when user is signed in' do
      before { sign_in(user) }

      context 'when form is invalid' do
        # stripe_token is missing from params
        let(:params) { { amount: '220.20', project_id: project.id, id: task.id } }

        it 'renders a json with invalid form parameters message' do
          make_request

          aggregate_failures("json is correct") do
            expect(response.status).to eq(500)
            expect(response.body).to include_json(
              error: "Submitted form parameters are invalid"
            )
          end
        end
      end

      context 'when form is valid' do
        let(:params) { { stripeToken: stripe_helper.generate_card_token, amount: '220.20', project_id: project.id, id: task.id } }

        context 'when there are not enough funds in reserve wallet' do
          before do
            allow_any_instance_of(Payments::BTC::WalletHandler).to receive(:get_wallet_balance).and_return(50)
          end

          it 'renders a json with correct message' do
            make_request

            aggregate_failures("json is correct") do
              expect(response.status).to eq(500)
              expect(response.body).to include_json(
                error: 'Not Enough BTC in Reserve wallet. Please Try Again'
              )
            end
          end
        end

        context 'when there are enough funds in reserve wallet' do
          before do
            allow_any_instance_of(Payments::BTC::WalletHandler).to receive(:get_wallet_balance).and_return(100_000_000)
          end

          shared_examples :declined_card do
            before do
              StripeMock.prepare_card_error(:card_declined)
            end

            it 'returns a json with corresponding error' do
              make_request

              aggregate_failures("json is correct") do
                expect(response.status).to eq(500)
                expect(response.body).to include_json(
                  error: 'The card was declined'
                )
              end
            end

          end

          context 'when a new card is entered without persisting it' do
            context 'when stripe payment succeeds', vcr: { cassette_name: "coinbase/transfer/success" } do
              it 'returns a json with success message' do
                make_request

                aggregate_failures("json is correct") do
                  expect(response.status).to eq(200)
                  expect(response.body).to include_json(
                    success: 'Thanks for your payment'
                  )
                end
              end
            end

            context 'when stripe payments fails' do
              it_behaves_like :declined_card
            end
          end

          context 'when a new card is entered and is selected to be persisted' do
            let(:stripe_token) { stripe_helper.generate_card_token }
            let(:amount) { '220.20' }
            let(:params) { { stripeToken: stripe_token, amount: amount, project_id: project.id, id: task.id, save_card: 'on' } }

            context 'when stripe payment succeeds', vcr: { cassette_name: "coinbase/transfer/success" } do
              it 'returns a json with success message' do
                make_request

                aggregate_failures("json is correct") do
                  expect(response.status).to eq(200)
                  expect(response.body).to include_json(
                    success: 'Thanks for your payment'
                  )
                end
              end

              it 'initializes the stripe payment service with the correct arguments' do
                expect(Payments::Stripe).to receive(:new).with(
                  stripe_token: stripe_token,
                  persist_card: true,
                  user: user
                ).and_call_original

                make_request
              end
            end

            context 'when stripe payment fails' do
              it_behaves_like :declined_card
            end
          end

          context 'when a saved card is selected', vcr: { cassette_name: "coinbase/transfer/success" } do
            let(:stripe_token) { stripe_helper.generate_card_token }
            let(:amount) { '220.20' }
            let(:params) { { card_id: @card_id, amount: amount, project_id: project.id, id: task.id, save_card: 'on' } }

            before do
              customer = Stripe::Customer.create({
                email: user.email,
                source: stripe_token
              })

              user.update_attributes(stripe_customer_id: customer.id)

              @card_id = customer.sources.first.id
            end

            context 'when stripe payment succeeds' do
              let(:message_delivery) { instance_double(ActionMailer::MessageDelivery) }
              let(:only_follower) { FactoryGirl.create(:user, :confirmed_user) }
              let(:follower_and_member) { FactoryGirl.create(:user, :confirmed_user) }

              before do
                allow(PaymentMailer).to receive(:fund_task).and_return(message_delivery)
                allow(message_delivery).to receive(:deliver_later)

                project_team = task.project.create_team(name: "Team#{task.id}")
                TeamMembership.create!(team_member: follower_and_member, team_id: project_team.id, role: 0)

                task.project.followers << only_follower
                task.project.followers << follower_and_member
                task.project.save!
              end

              it 'returns a json with success message' do
                make_request

                aggregate_failures("json is correct") do
                  expect(response.status).to eq(200)
                  expect(response.body).to include_json(
                    success: 'Thanks for your payment'
                  )
                end
              end

              it 'sends an email to the involved users', :aggregate_failures do
                expect(PaymentMailer).to receive(:fund_task).exactly(3).times
                expect(message_delivery).to receive(:deliver_later).exactly(3).times

                make_request
              end

              it 'initializes the stripe payment service with the correct arguments' do
                expect(Payments::Stripe).to receive(:new).with(
                  card_id: @card_id,
                  user: user
                ).and_call_original

                make_request
              end
            end

            context 'when stripe payment fails' do
              it_behaves_like :declined_card
            end
          end
        end
      end
    end
  end
end
