require "omnicontacts"

Rails.application.middleware.use OmniContacts::Builder do
  importer :gmail, "449109251723-mt5jbuh9i5oblsdldos89109q3laum08.apps.googleusercontent.com", "MO6NyX1rofV083BSPzJvklKF", {:redirect_path => "/oauth2callback"}
  #Development
  # importer :yahoo, "dj0yJmk9ZmNRNzN2Zkx0T0UzJmQ9WVdrOVJEZEViVXRMTXpJbWNHbzlNQS0tJnM9Y29uc3VtZXJzZWNyZXQmeD1mOQ--", "6b513da14b41b15761e1a574b864cf5b728418af", {:callback_path => '/callback'}
  #Production
  importer :yahoo, "dj0yJmk9bVZDd2VJV25weXo5JmQ9WVdrOVNVbHRiVTV6Tkc4bWNHbzlNQS0tJnM9Y29uc3VtZXJzZWNyZXQmeD1mYQ--", "3e5a9f246aff1142a1f1c5556e5243414d7aa350", {:callback_path => '/callback'}
end
