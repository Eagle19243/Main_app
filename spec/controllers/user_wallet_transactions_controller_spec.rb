require 'rails_helper'

RSpec.describe UserWalletTransactionsController, vcr: { cassette_name: 'bitgo' } do
  let(:user)          { create(:user, :confirmed_user) }
  let(:redirect_url)  { my_wallet_user_url(user) }

  before { sign_in(user) }

  describe '#send_to_task_address' do
    let(:wallet_address) { FactoryGirl.create(:wallet_address) }
    let(:task) { FactoryGirl.create(:task, wallet_address: wallet_address) }

    context 'tranfer error' do
      it do
        allow_any_instance_of(
          Payments::BTC::FundTask
        ).to receive(:submit!) { raise Payments::BTC::Errors::TransferError, 'Some Error' }

        post :send_to_task_address, amount: 20, task_id: task.id, format: 'js'
        message = assigns(:message)

        expect(message).to include('Some Error')
      end
    end

    context 'satoshi_amount' do
      context 'blank' do
        it do
          post :send_to_task_address, task_id: task.id, format: 'js'

          message = assigns(:message)
          expect(message).to include("Amount can't be less than minimum allowed size")
        end
      end

      context 'less than a minimum' do
        it do
          post :send_to_task_address, task_id: task.id, amount: "0.0001", format: 'js'

          message = assigns(:message)
          expect(message).to include("Amount can't be less than minimum allowed size")
        end
      end
    end

    context 'send coins error' do
      it do
        allow_any_instance_of(Bitgo::V1::Api).to receive(:send_coins_to_address) { { 'message' => 'Invalid amount' } }

        post :send_to_task_address, task_id: task.id, amount: 20, format: 'js'
        message = assigns(:message)

        expect(message).to eq('Invalid amount')
      end
    end

    context 'send success' do
      context 'fail to save transaction' do
        it do
          allow_any_instance_of(Bitgo::V1::Api).to receive(:send_coins_to_address) { { 'status' => '200' } }
          allow_any_instance_of(UserWalletTransaction).to receive(:save) { false }

          post :send_to_task_address, task_id: task.id, amount: 20, format: 'js'
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

    context 'send coins error' do
      it do
        allow_any_instance_of(Bitgo::V1::Api).to receive(:send_coins_to_address) { { 'message' => 'Invalid amount' } }

        post :send_to_any_address, wallet_transaction_user_wallet: 'user_wallet', amount: 20
        message = assigns(:message)

        expect(response).to redirect_to(redirect_url)
        expect(message).to eq('Invalid amount')
      end
    end

    context 'send success' do
      context 'fail to save transaction' do
        it do
          allow_any_instance_of(Bitgo::V1::Api).to receive(:send_coins_to_address) { { 'status' => '200' } }
          allow_any_instance_of(UserWalletTransaction).to receive(:save) { false }

          post :send_to_any_address, wallet_transaction_user_wallet: 'user_wallet', amount: 20

          expect(response).to redirect_to(redirect_url)
        end
      end
    end
  end
end
