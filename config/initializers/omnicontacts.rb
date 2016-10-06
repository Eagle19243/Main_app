require "omnicontacts"

Rails.application.middleware.use OmniContacts::Builder do
  importer :gmail, "449109251723-mt5jbuh9i5oblsdldos89109q3laum08.apps.googleusercontent.com", "MO6NyX1rofV083BSPzJvklKF", {:redirect_path => "/oauth2callback"}
end