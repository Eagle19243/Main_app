class PaymentNotificationsController < ApplicationController
  protect_from_forgery :except => [:create] #Otherwise the request from PayPal wouldn't make it to the controller
  def create
    response = validate_IPN_notification(request.raw_post)
    case response
      when "VERIFIED"
        puts params
        if params[:status] == "COMPLETED"
          # logger.info("++++++++++++++++++++++++++++++++++++++")
          puts "++++++++++++++++++++++++++++++++++++++++++++++"
          # check that paymentStatus=Completed
          # check that txnId has not been previously processed
          # check that receiverEmail is your Primary PayPal email
          # check that paymentAmount/paymentCurrency are correct
          # process payment
          @donation = Donation.find_by PAYKEY: params[:pay_key]
          @donation.task.update_attribute(:current_fund, @donation.task.current_fund + @donation.amount)
          @donation.task.update_attribute(:marker, true)
          @donation.update_attributes notification_params: params, status: params[:status], transaction_id: params[:txn_id], completed_at: Time.now

        end
      when "INVALID"
        # log for investigation
        puts " Moussa, transaction is invalid"
      else
        # error
    end
    render :nothing => true
  end

  protected
  def validate_IPN_notification(raw)
    uri = URI.parse('https://www.sandbox.paypal.com/cgi-bin/webscr?cmd=_notify-validate')
    # uri = URI.parse('https://www.paypal.com/cgi-bin/webscr?cmd=_notify-validate')
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 60
    http.read_timeout = 60
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http.use_ssl = true
    response = http.post(uri.request_uri, raw,
                         'Content-Length' => "#{raw.size}",
                         'User-Agent' => "My custom user agent"
    ).body
  end
end
