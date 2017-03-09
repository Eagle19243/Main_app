class UserWalletTransactionsController < ApplicationController
  include ApplicationHelper
  before_action :authenticate_user!

  def new
    @user_wallet_transaction = UserWalletTransaction.new
  end

  def user_keys
    "Here Your Wallet keys please save these keys to a Secure place \n" +
    " User Key : \n "+(current_user.user_wallet_address.user_keys  rescue "Not Found \n ") +
        " \n User Backup Keys: \n "+
        ( current_user.user_wallet_address.backup_keys rescue "Not Found \n ")
  end

  def  create_wallet
    if current_user.user_wallet_address.blank?
      current_user.assign_address
      redirect_to user_wallet_transactions_new_path , alert: "Wallet Created"
    else
      redirect_to user_path(current_user) , alert: "your Wallet Already Exist"
    end
  end

  def create
    current_user.assign_address if current_user.user_wallet_address.blank?

    begin
      @transfer = UserWalletTransaction.new(amount: params['amount'], user_wallet: params['wallet_transaction_user_wallet'], user_id: current_user.id)

      satoshi_amount = nil
      satoshi_amount = convert_btc_to_satoshi(params['amount']) if @transfer.valid?

      if satoshi_amount.blank?
        # satoshi_amount=150761.0
        respond_to do |format|
          @msg = 'Error, Please try again Later!'
          format.js
          format.html { redirect_to my_wallet_user_url(current_user), alert:  @msg }
        end
      else
        # TODO This should be extracted into the concern that will be then reused by the whole system
        access_token = Payments::BTC::Base.bitgo_access_token
        address_from = current_user.user_wallet_address.wallet_id
        sender_wallet_pass_phrase = current_user.user_wallet_address.pass_phrase
        address_to = params['wallet_transaction_user_wallet'].strip
        api = Bitgo::V1::Api.new

        @res = api.send_coins_to_address(wallet_id: address_from, address: address_to, amount: satoshi_amount , wallet_passphrase: sender_wallet_pass_phrase, access_token: access_token)

        if @res['message'].present?
          respond_to do |format|
            @msg = @res['message']
            format.js
            format.html { redirect_to my_wallet_user_url(current_user), alert: @msg }
          end
        else
          @transfer.tx_hash = @res['tx']
          @transfer.user_id = current_user.id

          if @transfer.save
            respond_to do |format|
              @msg = "#{params["amount"]} BTC has been successfully sent to #{@transfer.user_wallet}."
              format.js
              format.html { redirect_to my_wallet_user_url(current_user), notice: @msg }
            end
          else
            respond_to do |format|
              @msg = @transfer.errors.messages.inspect
              format.js
              format.html { redirect_to my_wallet_user_url(current_user), alert: @msg }
            end
          end
        end
      end
    rescue => e
      respond_to do |format|
        @msg = e.inspect
        @msg.slice! '#<Bitgo::V1::ApiError: '
        @msg = @msg.chomp '>'
        format.js
        format.html { redirect_to my_wallet_user_url(current_user), alert: @msg }
      end
    end
  end
end
