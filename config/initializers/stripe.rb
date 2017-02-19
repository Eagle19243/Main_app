Rails.configuration.stripe = {
  publishable_key: %w(test development staging).include?(Rails.env) ? 'pk_test_ycU0dr8SGu4MLeOwV07Y56za' : ENV['PUBLISHABLE_KEY_STRIPE'],
  secret_key: %w(test development staging).include?(Rails.env) ? 'sk_test_lOHuENad4WBr0didosuNYKx3' : ENV['SECRET_KEY_STRIPE']
}

Stripe.api_key = Rails.configuration.stripe[:secret_key]
