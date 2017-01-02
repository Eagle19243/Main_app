class Payments::StripeController < ApplicationController
  before_filter :check_form_validity, only: :create

  def new
    @task = Task.find(params[:id])
  end

  def create
    payment_service = Payments::Stripe.new(params[:stripeToken])
    payment_description = "Payment of #{params[:amount]} for task: #{params[:id]} for project: #{params[:project_id]}"



    if payment_service.charge!(amount: params[:amount], description: payment_description)
      # 1: TO DO: convert this USD amount from Dollars to Satoshi
      # 2: TO DO: Transfer this amount of Satoshi from the general WeServe BitGO account to the the one that belongs to the task wallet_id
      # params[:wallet_transaction_user_wallet] is available and is the one that can be used to move the money from the general WeServeBitGo

      flash[:notice] = 'Thanks for your payment'
      redirect_to taskstab_project_url(id: params[:project_id])
    else
      flash[:alert] = payment_service.error
      render :new
    end

  end

  private

  def check_form_validity
    # suspicious form without stripe_token or/and amount, send him back to the form to get these
    redirect_to(card_payment_project_task_url) unless params.key?(:stripeToken) && params.key?(:amount)
  end
end
