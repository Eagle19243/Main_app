require 'rails_helper'

RSpec.describe Payments::StripeController, vcr: { cassette_name: 'bitgo' } do
  render_views

  let(:task) { FactoryGirl.create(:task, :with_associations, :with_wallet) }
  let(:user) { task.user }
  let(:project) { task.project }

  before do
    stub_env('reserve_wallet_id', 'test-wallet-id')
    stub_env('reserve_wallet_pass_pharse', 'test-wallet-passphrase')

    allow_any_instance_of(User).to receive(:assign_address).and_return(
      UserWalletAddress.create(receiver_address: nil, user_id: user.id)
    )
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
    let(:stripe_helper) { StripeMock.create_test_helper }
    subject(:make_request) { post(:create, params) }

    before do
      StripeMock.start
      sign_in(user)
    end

    after { StripeMock.stop }

    context 'when form is invalid' do
      # stripe_token is missing from params
      let(:params) { { amount: '220.20', project_id: project.id, id: task.id } }

      it 'redirects to card_payment_project_url' do
        make_request
        expect(response).to redirect_to(card_payment_project_task_url)
      end
    end

    context 'when form is valid' do
      let(:params) { { stripeToken: stripe_helper.generate_card_token, amount: '220.20', project_id: project.id, id: task.id } }

      context 'when there are not enough funds in reserve wallet' do
        before do
          allow_any_instance_of(Payments::BTC::WalletHandler).to receive(:get_wallet_balance).and_return(50)
        end

        it 'redirects to the tasktab of the projects' do
          make_request
          expect(response).to redirect_to(taskstab_project_url(id: project.id))
        end

        it 'flashes the correct message' do
          make_request
          expect(flash[:alert]).to eq('Not Enough BTC in Reserve wallet Please Try Again.')
        end
      end

      context 'when there are enough funds in reserve wallet' do
        before do
          allow_any_instance_of(Payments::BTC::WalletHandler).to receive(:get_wallet_balance).and_return(100_000_000)
          allow_any_instance_of(Payments::BTC::Transfer).to receive(:submit!).and_return(true)
        end

        shared_examples :declined_card do
          before do
            StripeMock.prepare_card_error(:card_declined)
          end

          it 'flashes the correct message and redirects back to taskbar' do
            make_request

            aggregate_failures do
              expect(flash[:alert]).to eq('The card was declined')
              expect(response).to redirect_to(taskstab_project_url(id: params[:project_id]))
            end
          end

        end

        context 'when a new card is entered without persisting it' do
          context 'when stripe payment succeeds' do
            it 'flashes the correct message and redirects' do
              make_request

              aggregate_failures do
                expect(flash[:notice]).to eq('Thanks for your payment')
                expect(response).to redirect_to(taskstab_project_url(id: params[:project_id]))
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

          context 'when stripe payment succeeds' do
            it 'flashes the correct message and redirects' do
              make_request

              aggregate_failures do
                expect(flash[:notice]).to eq('Thanks for your payment')
                expect(response).to redirect_to(taskstab_project_url(id: params[:project_id]))
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

        context 'when a saved card is selected' do
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
            it 'flashes the correct message and redirects' do
              make_request

              aggregate_failures do
                expect(flash[:notice]).to eq('Thanks for your payment')
                expect(response).to redirect_to(taskstab_project_url(id: params[:project_id]))
              end
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
