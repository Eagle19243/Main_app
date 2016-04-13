class Donation < ActiveRecord::Base
  require "pp-adaptive"
	belongs_to :user
	belongs_to :task


 validates_numericality_of :amount, :only_integer => true, :greater_than_or_equal_to => 1


def payment_url(submission)

  client = AdaptivePayments::Client.new(
  :user_id       => "ec2699_api1.columbia.edu",
  :password      => "DPBP5S9EFP6YZWDQ",
  :signature     => "AFcWxV21C7fd0v3bYYYRCpSSRl31ARu.A6SKwsbj1JpFvVtqefXfrLef",
  :app_id        => "APP-80W284485P519543T",
  :sandbox       => true
)

  amount = submission.amount
  recipient_cut = amount * 0.9

  # Recipient Email must be 
  recipient_email = "e.c.mere@gmail.com"

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
