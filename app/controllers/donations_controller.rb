class DonationsController < ApplicationController
  def new
    @task = Task.find(params[:task_id])
    @donation = Donation.new
  end

  def create
    @donation = Donation.new(donation_params)
    if @donation.save!
      client = AdaptivePayments::Client.new(
        user_id:   'ec2699_api1.columbia.edu',
        password:  'DPBP5S9EFP6YZWDQ',
        signature: 'AFcWxV21C7fd0v3bYYYRCpSSRl31ARu.A6SKwsbj1JpFvVtqefXfrLef',
        app_id:    'APP-80W284485P519543T',
        sandbox:   true
      )

      amount = @donation.amount
      # Recipient Email must be
      recipient_email = 'e.c.mere@gmail.com'

      client.execute(:Pay,
        action_type:        'PAY_PRIMARY',
        currency_code:      'USD',
        cancel_url:         "http://localhost:3000/tasks/#{@donation.task_id}",
        return_url:         "http://localhost:3000/tasks/#{@donation.task_id}",
        ipnNotificationUrl: 'http://localhost:3000/payment_notifications',
        receivers: [
          { email: 'e.c.mere@gmail.com', amount: amount, primary: true },
          { email: 'testyouserve1@gmail.com', amount: 0.02 * amount, primary: false },
          { email: 'testyouserve2@gmail.com', amount: 0.02 * amount, primary: false },
          { email: 'francischebalier@gmail.com', amount: 0.02 *amount, primary: false }
        ]
      ) do |response|
        if response.success?
          puts "Pay key: #{response.pay_key}"
          @donation.update_attribute(:PAYKEY, response.pay_key)

          # send the user to PayPal to make the payment
          # e.g. "https://www.sandbox.paypal.com/webscr?cmd=_ap-payment&paykey=#{response.pay_key}
           redirect_to ("https://www.sandbox.paypal.com/webscr?cmd=_ap-payment&paykey=#{response.pay_key}")
        else
          puts "#{response.ack_code}: #{response.error_message}"
        end
      end

    else
      redirect_to @donation.task
      flash[:error] = 'Please Enter a valid amount'
    end
  end

  private

  def donation_params
    params.require(:donation).permit(:task_id, :amount, :paypal_email, :PAYKEY,
                                     :current_fund, :transaction_id, :status,:notification_params, :completed_at )
  end
end
