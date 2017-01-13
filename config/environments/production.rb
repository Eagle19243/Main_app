Rails.application.configure do

  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true
  config.assets.js_compressor = :uglifier
  config.assets.compile = true
  config.assets.digest = true
  config.serve_static_assets = true
  config.log_level = :debug
  config.i18n.fallbacks = true
  config.active_support.deprecation = :notify
  config.log_formatter = ::Logger::Formatter.new
  config.consider_all_requests_local = ENV['consider_all_requests_local'] || false

  config.action_mailer.smtp_settings = {
    address: "email-smtp.eu-west-1.amazonaws.com",
    port: 587,
    authentication: :login,
    enable_starttls_auto: true,
    user_name: ENV["email_provider_username"],
    password: ENV["email_provider_password"],
  }
  
  config.action_mailer.default_url_options = { :host => ENV["default_url"] }
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true

  config.active_record.dump_schema_after_migration = false

  config.react.variant = :production
  config.react.addons = true

end