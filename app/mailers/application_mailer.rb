class ApplicationMailer < ActionMailer::Base
  default from: ENV['mailer_sender']
  layout 'mailer'
end
