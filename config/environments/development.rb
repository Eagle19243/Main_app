Rails.application.configure do

  config.cache_classes = false
  config.eager_load = false
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false
  config.action_mailer.raise_delivery_errors = false
  config.active_support.deprecation = :log
  config.active_record.migration_error = :page_load
  config.assets.debug = true

  config.action_mailer.smtp_settings = {
    address: "email-smtp.eu-west-1.amazonaws.com",
    port: 587,
    domain: ENV["domain_name"],
    authentication: "plain",
    enable_starttls_auto: true,
    user_name: ENV["email_provider_username"],
    password: ENV["email_provider_password"],
    from: "example@localhost.com"
  }

  config.action_mailer.default_url_options = { :host => 'localhost:3000' }
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.perform_deliveries = false

  config.assets.digest = true
  config.assets.raise_runtime_errors = true
  config.serve_static_files = true

  config.react.variant  = :development
  config.react.addons = true

end
