class ApplicationMailer < ActionMailer::Base
  default from: ENV['weserve_from_email']
  layout 'mailer'
end
