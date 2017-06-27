Rails.configuration.stripe = {
  publishable_key: %w(test development staging).include?(Rails.env) ? 'pk_test_ZeUjuyRgxBFMrn0rAVu7156Q' : ENV['PUBLISHABLE_KEY_STRIPE'],
  secret_key: %w(test development staging).include?(Rails.env) ? 'sk_test_y2wKfJ1NEw2C9yKIouxuI8jo' : ENV['SECRET_KEY_STRIPE']
}

Stripe.api_key = Rails.configuration.stripe[:secret_key]
