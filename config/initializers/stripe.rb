Rails.configuration.stripe = {
  publishable_key: %w(test development staging).include?(Rails.env) ? 'pk_test_ykedPWfCSpJViEj2ga9qBZN9' : ENV['PUBLISHABLE_KEY_STRIPE'],
  secret_key: %w(test development staging).include?(Rails.env) ? 'sk_test_fvzVxhNx5UnQSHxraKJLpVmz' : ENV['SECRET_KEY_STRIPE']
}

Stripe.api_key = Rails.configuration.stripe[:secret_key]
