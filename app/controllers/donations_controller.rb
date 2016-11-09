class DonationsController < ApplicationController
  include PayPal::SDK::AdaptivePayments
  def new

    @task = Task.find(params[:task_id])
    if @task.suggested_task?
      flash[:error] = "You can not Apply For Suggested Task "
      redirect_to task_path(@task.id)
    end
    @donation = Donation.new
  end

  def create
    @donation = Donation.new(donation_params)

    if @donation.save!

      @api = PayPal::SDK::AdaptivePayments.new
      amount = @donation.amount
      @pay = @api.build_pay({
                                :actionType => "PAY",
                                :cancelUrl => request.base_url + "/tasks/#{@donation.task_id}",
                                :currencyCode => "USD",
                                :ipnNotificationUrl => payment_notifications_url, #payment_ipn_notify_url, #request.base_url + "/payment_notifications",
                                :receiverList => {
                                    :receiver => [
                                        { :email => "bruno19850511-facilitator@yahoo.com", :amount => amount },
                                        { :email => "testyouserve1@gmail.com", :amount => 0.02*amount, :primary => false },
                                        { :email => "testyouserve2@gmail.com", :amount => 0.02*amount, :primary => false },
                                        { :email => "francischebalier@gmail.com", :amount => 0.02*amount, :primary => false }
                                    ] },
                                :returnUrl => request.base_url + "/tasks/#{@donation.task_id}" })


      response = @api.pay(@pay)
      if response.success?
        puts "Pay key: #{response.pay_key}"
        @donation.update_attribute(:PAYKEY,response.payKey)
        puts "before response"
        puts @donation
        # send the user to PayPal to make the payment
        # e.g. "https://www.sandbox.paypal.com/webscr?cmd=_ap-payment&paykey=#{response.pay_key}
        # redirect_to ("https://www.sandbox.paypal.com/webscr?cmd=_ap-payment&paykey=#{response.pay_key}")
        @donation.task.project.follow!(current_user)
        redirect_to @api.payment_url(response)
      else
        puts response.error[0].message
        # puts "#{response.ack_code}: #{response.error_message}"
      end

    else
      redirect_to @donation.task
      flash[:error] = "Please Enter a valid amount"
    end
  end

  private

  def donation_params
    params.require(:donation).permit(:task_id, :amount, :paypal_email, :PAYKEY,
                                     :current_fund, :transaction_id, :status, :notification_params, :completed_at )
  end
end
