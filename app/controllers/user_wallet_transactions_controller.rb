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

    transfer = Payments::BTC::TransferFromUserWallet.new(
      wallet: current_user.user_wallet_address,
      amount: convert_btc_to_satoshi(params[:amount]),
      address_to: params['wallet_transaction_user_wallet'],
      user: current_user
    )

    transfer.submit!

    @msg = "#{transfer.amount} BTC has been successfully sent to #{transfer.address_to}."
  rescue Payments::BTC::Errors::TransferError => error
    @msg = error.message
  ensure
    respond_to do |format|
      format.js
      format.html { redirect_to my_wallet_user_url(current_user), alert: @msg }
    end
  end
end
