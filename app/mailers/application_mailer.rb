class ApplicationMailer < ActionMailer::Base
  default from: ENV['weserve_from_email']
  layout 'mailer'

  def reserve_wallet_low_balance(satoshi_balance)
    @balance = Payments::BTC::Converter.convert_satoshi_to_btc(satoshi_balance)
    mail(to: ENV['admin_notification_email'], subject: 'Reserve wallet balance is getting low')
  end

end
