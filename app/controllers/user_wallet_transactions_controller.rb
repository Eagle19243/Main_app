class UserWalletTransactionsController < ApplicationController

  before_action :authenticate_user!

  def new
    @user_wallet_transaction = UserWalletTransaction.new
  end

  def create

    begin
      @transfer = UserWalletTransaction.new(amount:params['amount'] ,user_wallet:params['wallet_transaction_user_wallet'] ,user_id: current_user.id)
      satoshi_amount = nil
      satoshi_amount = convert_usd_to_btc_and_then_satoshi(params['amount']) if @transfer.valid?
      if satoshi_amount.eql?('error') or satoshi_amount.blank?
        # satoshi_amount=150761.0
        respond_to do |format|
          format.html { redirect_to user_path(current_user.id) , alert: 'Error, Please try again Later!' }
        end
      else
        access_token = access_wallet
        address_from = current_user.user_wallet_address.wallet_id
        sender_wallet_pass_phrase = current_user.user_wallet_address.pass_phrase
        address_to = params['wallet_transaction_user_wallet'].strip
        api = Bitgo::V1::Api.new(Bitgo::V1::Api::EXPRESS)
        @res = api.send_coins_to_address(wallet_id: address_from, address: address_to, amount:satoshi_amount , wallet_passphrase: sender_wallet_pass_phrase, access_token: access_token)
        unless @res["message"].blank?
          respond_to do |format|
            format.html {redirect_to user_path(current_user.id)   , alert: @res["message"] }
          end
        else
          @transfer.tx_hash = @res["tx"]
          @transfer.user_id = current_user.id

          if(@transfer.save!)
            respond_to do |format|
              format.html {redirect_to user_path(current_user.id)  , notice: " #{params["amount"]} usd has been successfully sent to #{@transfer.user_wallet}." }

            end
          else
            respond_to do |format|
              format.html { redirect_to user_path(current_user.id)  , alert: @transfer.errors.messages.inspect }
            end
          end
        end
      end
    rescue => e
      respond_to do |format|
        format.html { redirect_to user_path(current_user.id)   , alert: e.inspect }
      end
    end

  end



end
