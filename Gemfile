source 'https://rubygems.org'
ruby '2.3.1'

gem 'rails', '4.2.5.1'
gem 'sass-rails', '~> 5.0'
gem 'bootstrap-sass'
gem 'autoprefixer-rails', '>= 5.2.1'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.1.0'
gem 'jquery-rails'
gem 'jbuilder', '~> 2.0'
gem 'country_select'
gem 'carrierwave', '~> 0.9'
gem 'carrierwave-crop'
gem 'mini_magick'
gem 'fog'
gem 'omnicontacts'
gem 'gravatar_image_tag'
gem 'groupify'
gem 'foundation-datetimepicker-rails'
gem 'jquery-ui-rails'
gem 'jquery-slick-rails'
gem 'tinymce-rails'
gem 'aasm'
gem 'social-share-button'
gem 'paypal-sdk-adaptivepayments'
gem 'pp-adaptive'
gem 'chosen-rails'
gem 'validates_timeliness', '~> 4.0'
gem 'interactor-rails', '~> 2.0'
gem 'puma'
gem 'sunspot_rails'
gem 'sunspot_solr'
gem 'rails4-autocomplete'
gem 'nokogiri', '1.6.0'
gem 'progress_bar'
gem 'dalli'
gem 'therubyracer'
gem 'react-rails'
gem 'zeroclipboard-rails'
gem 'rufus-scheduler'
gem "font-awesome-rails"
gem 'omniauth'
gem 'omniauth-facebook'
gem 'omniauth-twitter'
gem 'omniauth-google-oauth2'
gem 'differ'
gem 'cocoon'
gem 'best_in_place', '~> 3.0.1'
gem 'cancancan', '~> 1.10'
gem 'kaminari'
gem 'rails-observers'
gem 'pg'
gem 'devise'
gem 'foundation-rails', '~> 5.5'
gem 'high_voltage'
gem 'simple_form'
gem 'newrelic_rpm'
gem 'figaro'
gem 'stripe'

# Ajax File Uploading
gem 'remotipart'

# ActAsParanoid
gem 'paranoia', "~> 2.0"

gem 'firebase_token_generator'

# A Rake task gem that helps you find the unused routes and controller actions for your Rails 3+ app
gem 'traceroute'

# Profiler for your development and production Ruby rack apps.
gem 'rack-mini-profiler'

# Help to kill N+1 queries and unused eager loading
gem "bullet", :group => "development"

# Bootstrap datetimepicker
gem 'momentjs-rails', '>= 2.9.0'
gem 'bootstrap3-datetimepicker-rails', '~> 4.17.43'

# A static analysis security vulnerability scanner for Ruby on Rails applications
group :development do
  gem 'brakeman', :require => false
  gem 'letter_opener'
  gem 'spring-commands-rspec'
end

# CSS coverage tool
group :test do
  gem 'colored'
  gem 'deadweight', :require => 'deadweight/hijack/rails'
  gem 'capybara'
  gem 'poltergeist'
  gem 'fivemat', require: false
  gem 'database_cleaner'
  gem 'vcr'
  gem 'webmock'
end

# Code metric tool for rails projects
gem "rails_best_practices"

# A Ruby static code analyzer, based on the community Ruby style guide.
gem 'rubocop', require: false

# A Ruby code quality reporter
gem "rubycritic", :require => false

# TDD/BDD Testing
group :development, :test do
  gem 'rspec-rails'
  gem 'factory_girl_rails'
  gem 'pry-rails'
end

group :test do
  gem 'faker'
end

# Auto deployment to AWS

group :development do
    gem 'capistrano',         require: false
    gem 'capistrano-rvm',     require: false
    gem 'capistrano-rails',   require: false
    gem 'capistrano-bundler', require: false
    gem 'capistrano3-puma',   require: false
end

group :development do
  gem 'better_errors'
  gem 'hub', :require=>nil
  gem 'quiet_assets'
  gem 'rails_layout'
  gem 'web-console', '~> 2.0'
  gem 'spring'
end

group :development, :test do
  gem 'sqlite3'
  gem 'byebug'
end
