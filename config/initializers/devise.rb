Devise.setup do |config|

  require 'devise/orm/active_record'

  config.mailer_sender = ENV["weserve_from_email"]
  config.secret_key = ENV["app_secret_key"]
  config.case_insensitive_keys = [:email]
  config.strip_whitespace_keys = [:email]
  config.skip_session_storage = [:http_auth]
  config.stretches = Rails.env.test? ? 1 : 10
  config.reconfirmable = true
  config.remember_for = 3.years
  config.expire_all_remember_me_on_sign_out = true
  config.password_length = 8..72
  config.timeout_in = 3.years
  config.reset_password_within = 6.hours
  config.navigational_formats = ['*/*', :html]
  config.sign_out_via = :delete

  config.omniauth :facebook, ENV["facebook_app_id"], ENV["facebook_secret_key"], image_size: { width: 400, height: 400 }
  config.omniauth :twitter, ENV["twitter_app_id"], ENV["twitter_secret_key"]
  config.omniauth :google_oauth2, ENV["gapp_id"], ENV["gapp_secret_key"], { access_type: "offline", approval_prompt: "", skip_jwt: true, image_size: { width: 400, height: 400 } }

end
