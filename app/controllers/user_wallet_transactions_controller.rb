class UserWalletTransactionsController < ApplicationController
  before_action :authenticate_user!

  def send_to_any_address
    transfer = Payments::BTC::FundBtcAddress.new(
      amount: amount_in_satoshi,
      address_to: params['wallet_transaction_user_wallet'],
      user: current_user
    )
    transfer.submit!

    @message = "#{params[:amount]} BTC has been successfully sent to #{transfer.address_to}."
    redirect_to my_wallet_user_url(current_user), notice: @message
  rescue Payments::BTC::Errors::TransferError => error
    ErrorHandlerService.call(error)
    @message = error.message
    redirect_to my_wallet_user_url(current_user), alert: @message
  end

  def send_to_task_address
    task = Task.find(params[:task_id])

    @transfer = Payments::BTC::FundTask.new(
      amount: amount_in_satoshi,
      task: task,
      user: current_user
    )
    @transfer.submit!

    render json: { success: "#{params[:amount]} BTC has been successfully sent to task's balance" }, status: 200
  rescue Payments::BTC::Errors::TransferError => error
    ErrorHandlerService.call(error)
    render json: { error: error.message }, status: 500
  end

  private
  def amount_in_satoshi
    Payments::BTC::Converter.convert_btc_to_satoshi(params[:amount])
  end
end
