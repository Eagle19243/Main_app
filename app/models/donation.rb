class Donation < ActiveRecord::Base
  require "pp-adaptive"
	belongs_to :user
	belongs_to :task





def payment_url(submission)

  client = AdaptivePayments::Client.new(
  :user_id       => "e.c.mere_api1.gmail.com",
  :password      => "HS992DBH2UFDKUAU",
  :signature     => "AFcWxV21C7fd0v3bYYYRCpSSRl31AVNew3w3TLO6iGOm3FunFv3.4Nwp",
  :app_id        => "your-app-id-left",
  :sandbox       => true
)

  amount = submission.amount
  recipient_cut = amount * 0.9
  recipient_email = submission.paypal_email

  client.execute(:Pay,
    :action_type     => "PAY",
    :currency_code   => "USD",
    :cancel_url      => "http://localhost:3000/tasks/#{submission.task_id}",
    :return_url      => "http://localhost:3000/tasks/#{submission.task_id}",
    :fees_payer      => "SECONDARYONLY",
    :receivers       => [
      { :email => recipient_email, :amount => recipient_cut, :primary => false },
      { :email => "TestApp@gmail.com", :amount => amount, :primary => true }
    ]
  ) do |response|

    if response.success?
      puts "Pay key: #{response.pay_key}"

      # send the user to PayPal to make the payment
      # e.g. https://www.sandbox.paypal.com/webscr?cmd=_ap-payment&paykey=abc
      return client.payment_url(response)
    else
      puts "#{response.ack_code}: #{response.error_message}"
    end

  end
  end









end
