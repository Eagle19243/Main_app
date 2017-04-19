require 'rails_helper'

RSpec.describe UserWalletTransactionsController do
  let!(:user) { create(:user, :confirmed_user) }
  let!(:wallet) { create(:wallet, wallet_id: "30a21ed2-4f04-57ae-9d21-becb751138f4", wallet_owner_id: user.id, wallet_owner_type: 'User') }
  let(:redirect_url)  { my_wallet_user_url(user) }

  context 'user is not signed in' do
    describe '#send_to_task_address' do
      let(:task) { FactoryGirl.create(:task, :with_wallet) }

      it do
        post :send_to_task_address, amount: 20, task_id: task.id, format: 'json'
        expect(response.body).to include_json(
          error: "You need to sign in or sign up before continuing."
        )
      end
    end

    describe '#send_to_any_address' do
      it do
        post :send_to_any_address, wallet_transaction_user_wallet: 'user_wallet', amount: 20, format: 'json'

        expect(response.body).to include_json(
          error: "You need to sign in or sign up before continuing."
        )
      end
    end
  end

  context 'user is signed in' do
    before { user.reload; sign_in(user) }

    describe '#send_to_task_address' do
      let(:project) { FactoryGirl.create(:project) }
      let(:task) { FactoryGirl.create(:task, :with_wallet, project: project) }
      let(:min_amount_in_btc) { Payments::BTC::Converter.convert_satoshi_to_btc(Payments::BTC::FundTask::MIN_AMOUNT) }

      context 'tranfer error' do
        it do
          allow_any_instance_of(
            Payments::BTC::FundTask
          ).to receive(:submit!) { raise Payments::BTC::Errors::TransferError, 'Some Error' }

          post :send_to_task_address, amount: 20, task_id: task.id, format: 'json'

          aggregate_failures("json is correct") do
            expect(response.status).to eq(500)
            expect(response.body).to include_json(error: 'Some Error')
          end
        end
      end

      context 'tranfer general error' do
        it do
          allow_any_instance_of(
            Payments::BTC::FundTask
          ).to receive(:submit!) { raise Payments::BTC::Errors::GeneralError, 'Coinbase API error' }

          post :send_to_task_address, amount: 20, task_id: task.id, format: 'json'

          aggregate_failures("json is correct") do
            expect(response.status).to eq(500)
            expect(response.body).to include_json(error: 'There is a temporary problem connecting to payment service. Please try again later')
          end
        end
      end

      context 'satoshi_amount' do
        context 'blank' do
          it do
            post :send_to_task_address, task_id: task.id, format: 'json'

            aggregate_failures("json is correct") do
              expect(response.status).to eq(500)
              expect(response.body).to include_json(
                error: "Amount can't be less than minimum allowed size (#{min_amount_in_btc} BTC)"
              )
            end
          end
        end

        context 'less than a minimum' do
          it do
            post :send_to_task_address, task_id: task.id, amount: "0.0001", format: 'json'

            aggregate_failures("json is correct") do
              expect(response.status).to eq(500)
              expect(response.body).to include_json(
                error: "Amount can't be less than minimum allowed size (#{min_amount_in_btc} BTC)"
              )
            end
          end
        end
      end

      context 'send success' do
        let(:message_delivery) { instance_double(ActionMailer::MessageDelivery) }
        let(:only_follower) { FactoryGirl.create(:user, :confirmed_user) }
        let(:follower_and_member) { FactoryGirl.create(:user, :confirmed_user) }

        before do
          allow(PaymentMailer).to receive(:fund_task).and_return(message_delivery)
          allow(message_delivery).to receive(:deliver_later)
          allow_any_instance_of(Payments::BTC::FundTask).to receive(:submit!) { true }

          project_team = task.project.create_team(name: "Team#{task.id}")
          TeamMembership.create!(team_member: follower_and_member, team_id: project_team.id, role: 0)

          task.project.followers << only_follower
          task.project.followers << follower_and_member
          task.project.save!
        end

        it 'returns success' do
          post :send_to_task_address, task_id: task.id, amount: 20, format: 'json'

          aggregate_failures("json is correct") do
            expect(response.status).to eq(200)
            expect(response.body).to include_json(
              success: "20 BTC has been successfully sent to task's balance"
            )
          end
        end

        context 'when the task is not fully funded' do
          it 'sends an email to the involved users', :aggregate_failures do
            expect(PaymentMailer).to receive(:fund_task).exactly(3).times
            expect(message_delivery).to receive(:deliver_later).exactly(3).times

            post :send_to_task_address, task_id: task.id, amount: 20, format: 'json'
          end
        end

        context 'when the task is fully funded' do
          let(:task) { FactoryGirl.create(:task, :with_wallet, project: project, budget: 200.0, current_fund: 200.0) }
          before { allow(PaymentMailer).to receive(:fully_funded_task).and_return(message_delivery) }

          it 'sends an email to the involved users', :aggregate_failures do
            expect(PaymentMailer).to receive(:fund_task).exactly(3).times
            # aggregate the deliver later
            expect(message_delivery).to receive(:deliver_later).exactly(6).times

            post :send_to_task_address, task_id: task.id, amount: 20, format: 'json'
          end

          it 'sends an email to the involved users that the task was fully funded', :aggregate_failures do
            expect(PaymentMailer).to receive(:fully_funded_task).exactly(3).times
            # aggregate the deliver later
            expect(message_delivery).to receive(:deliver_later).exactly(6).times

            post :send_to_task_address, task_id: task.id, amount: 20, format: 'json'
          end
        end
      end
    end

    describe '#send_to_any_address' do
      context 'tranfer error' do
        it do
          allow_any_instance_of(
            Payments::BTC::FundBtcAddress
          ).to receive(:submit!) { raise Payments::BTC::Errors::TransferError, 'Some Error' }

          post :send_to_any_address, amount: 20, wallet_transaction_user_wallet: 'user_wallet'
          message = assigns(:message)

          expect(response).to redirect_to(redirect_url)
          expect(message).to include('Some Error')
        end
      end

      context 'tranfer error' do
        it do
          allow_any_instance_of(
            Payments::BTC::FundBtcAddress
          ).to receive(:submit!) { raise Payments::BTC::Errors::GeneralError, 'Coinbase API error' }

          post :send_to_any_address, amount: 20, wallet_transaction_user_wallet: 'user_wallet'
          message = assigns(:message)

          expect(response).to redirect_to(redirect_url)
          expect(message).to include('There is a temporary problem connecting to payment service. Please try again later')
        end
      end

      context 'satoshi_amount' do
        context 'blank' do
          it do
            post :send_to_any_address, wallet_transaction_user_wallet: 'user_wallet'

            expect(response).to redirect_to(redirect_url)
            message = assigns(:message)
            expect(message).to include("Amount can't be blank")
          end
        end

        context 'less than a minimum' do
          it do
            post :send_to_any_address, wallet_transaction_user_wallet: 'user_wallet', amount: "0.0001"

            expect(response).to redirect_to(redirect_url)
            message = assigns(:message)
            expect(message).to include("Amount can't be less than 0.001 BTC")
          end
        end
      end

      context 'address_to' do
        context 'blank' do
          it do
            post :send_to_any_address, wallet_transaction_user_wallet: nil, amount: 20

            expect(response).to redirect_to(redirect_url)
            message = assigns(:message)
            expect(message).to include("Recieve address can't be blank")
          end
        end
      end

      context 'send success' do
        it do
          allow_any_instance_of(Payments::BTC::FundBtcAddress).to receive(:submit!) { true }

          post :send_to_any_address, wallet_transaction_user_wallet: 'user_wallet', amount: 20

          expect(response).to redirect_to(redirect_url)
          message = assigns(:message)
          expect(message).to include("20 BTC has been successfully sent to user_wallet.")
        end
      end
    end
  end
end
