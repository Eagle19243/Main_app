require 'rails_helper'

RSpec.describe UserWalletTransactionsController, vcr: { cassette_name: 'bitgo' } do
  let(:user)          { create(:user, :confirmed_user) }
  let(:redirect_url)  { my_wallet_user_url(user) }

  before { sign_in(user) }

  describe '#create' do
    context 'tranfer error' do
      it do
        allow_any_instance_of(
          Payments::BTC::TransferFromUserWallet
        ).to receive(:submit!) { raise Payments::BTC::Errors::TransferError, 'Some Error' }

        post :create, amount: 20, wallet_transaction_user_wallet: 'user_wallet'
        msg = assigns(:msg)

        expect(response).to redirect_to(redirect_url)
        expect(msg).to include('Some Error')
      end
    end

    context 'satoshi_amount' do
      context 'blank' do
        it do
          post :create, wallet_transaction_user_wallet: 'user_wallet'

          expect(response).to redirect_to(redirect_url)
          msg = assigns(:msg)
          expect(msg).to include("Amount can't be blank")
        end
      end

      context 'less than a minimum' do
        it do
          post :create, wallet_transaction_user_wallet: 'user_wallet', amount: "0.0001"

          expect(response).to redirect_to(redirect_url)
          msg = assigns(:msg)
          expect(msg).to include("Amount can't be less than 0.001 BTC")
        end
      end
    end

    context 'address_to' do
      context 'blank' do
        it do
          post :create, wallet_transaction_user_wallet: nil, amount: 20

          expect(response).to redirect_to(redirect_url)
          msg = assigns(:msg)
          expect(msg).to include("Recieve address can't be blank")
        end
      end
    end

    context 'send coins error' do
      it do
        allow_any_instance_of(Bitgo::V1::Api).to receive(:send_coins_to_address) { { 'message' => 'Invalid amount' } }

        post :create, wallet_transaction_user_wallet: 'user_wallet', amount: 20
        msg = assigns(:msg)

        expect(response).to redirect_to(redirect_url)
        expect(msg).to eq('Invalid amount')
      end
    end

    context 'send success' do
      context 'fail to save transaction' do
        it do
          allow_any_instance_of(Bitgo::V1::Api).to receive(:send_coins_to_address) { { 'status' => '200' } }
          allow_any_instance_of(UserWalletTransaction).to receive(:save) { false }

          post :create, wallet_transaction_user_wallet: 'user_wallet', amount: 20

          expect(response).to redirect_to(redirect_url)
        end
      end
    end
  end
end
