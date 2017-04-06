class Payments::StripeController < ApplicationController
  before_filter :check_form_validity, only: :create
  before_action :authenticate_user!

  def new
    @task = Task.find(params[:id])
    @available_cards = Payments::StripeSources.new.call(user: current_user)
  end

  def create
    task = Task.find(params[:id])
    transfer = Payments::BTC::FundTaskFromReserveWallet.new(
      task:         task,
      user:         current_user,
      usd_amount:   params[:amount].to_f,
      stripe_token: params[:stripeToken],
      card_id:      params[:card_id],
      save_card:    params[:save_card]
    )
    transfer.submit!

    render json: { success: 'Thanks for your payment' }, status: 200
  rescue Payments::BTC::Errors::TransferError => error
    ErrorHandlerService.call(error)
    render json: { error: UserErrorPresenter.new(error).message }, status: 500
  end

  private

  def check_form_validity
    unless (params.key?(:stripeToken) || params.key?(:card_id)) && params.key?(:amount)
      render json: { error: "Submitted form parameters are invalid" }, status: 500
    end
  end
end
