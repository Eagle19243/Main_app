class Payments::StripeController < ApplicationController
  before_filter :check_form_validity, only: :create
  include ApplicationHelper

  def new
    @task = Task.find(params[:id])
  end

  def create
    payment_service = Payments::Stripe.new(params[:stripeToken])
    payment_description = "Payment of #{params[:amount]} for task: #{params[:id]} for project: #{params[:project_id]}"


    if payment_service.charge!(amount: params[:amount], description: payment_description)
      task = Task.find(params[:id])
      transfer_coin_from_weserver_wallet_to_task_wallet(task, params[:amount])
      # task_id :   amount:;
      #   rails generate model StripePayments amount:decimal task:references
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

  def transfer_coin_from_weserver_wallet_to_task_wallet (task, amount)
    we_serve_wallet
    task_wallet = task.wallet_address.sender_address
    begin
      @transfer = StripePayment.create(amount: amount, task_id: task.id)
      satoshi_amount = nil
      satoshi_amount = convert_usd_to_btc_and_then_satoshi(amount) if @transfer.valid?
      if satoshi_amount.eql?('error') or satoshi_amount.blank?
        return
      else
        access_token = access_wallet
        address_from = @wallet_id
        sender_wallet_pass_phrase = @passphrase
        address_to = task_wallet.strip

        api = Bitgo::V1::Api.new(Bitgo::V1::Api::EXPRESS)
        @res = api.send_coins_to_address(wallet_id: address_from, address: address_to, amount: satoshi_amount, wallet_passphrase: sender_wallet_pass_phrase, access_token: access_token)
        if @res["message"].blank?
          @transfer.tx_hash = @res["tx"]
          @transfer.transferd = true
          @transfer.save!
        end
      end
    end

  end


  def check_form_validity
    # suspicious form without stripe_token or/and amount, send him back to the form to get these
    redirect_to(card_payment_project_task_url) unless params.key?(:stripeToken) && params.key?(:amount)
  end
end
