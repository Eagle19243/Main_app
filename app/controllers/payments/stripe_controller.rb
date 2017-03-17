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

    flash[:notice] = 'Thanks for your payment'
  rescue Payments::BTC::Errors::TransferError => error
    flash[:alert] = error.message
  ensure
    redirect_to taskstab_project_url(id: params[:project_id])
  end

  private

  def check_form_validity
    redirect_to(card_payment_project_task_url) unless (params.key?(:stripeToken) || params.key?(:card_id)) && params.key?(:amount)
  end
end
