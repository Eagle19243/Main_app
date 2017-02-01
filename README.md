# Requirements

- Ruby 2.2.1
- Rails 4.2.5.1
- PostgreSQL
- NodeJS 4.x
- [Mediawiki](https://mediawiki.org) 1.25+

# Steps to run the app

### 1. Prepare environment

* Install & configure Git
* Install & configure PostgreSQL database
* Install NodeJS
* Clone the repository and perform `bundle install`

### 2. Get necessary tokens

* Create an account at http://bitgo.com
* Generate 2 development tokens with full set of permissions
* Not necessary, but recommended: create app tokens at your Facebook, Twitter and Google accounts

### 3. Configure Mediawiki

This step requires you either configure local Mediawiki instance or use our staging Mediawiki instance.
This step can be omited for now, ask other developers for Mediawiki credentials.

### 4. Create configuration files

* Copy `config/application.yml.exampe` to `config/application.yml`
* Fill values following comments in this file
* Copy `config/database.yml.example` to `config/database.yml` and specify yur PostgreSQL credentials

### 5. Run BigGoJS

* Clone [ButGoJS repository](https://github.com/BitGo/BitGoJS) in a separate directory
* Run `npm install`
* Run it with command `./bitgo-express --debug --port 3080 --env prod --bind localhost`

### 6. Run Solr

* Being in app directory run `RAILS_ENV=development bundle exec rake sunspot:solr:start`
* Ensure that Solr is running without errors

### 7. Migrate database

* Being in app directory run `RAILS_ENV=development bundle exec rake db:create db:schema:load db:migrate`
* If necessary, run `RAILS_ENV=development bundle exec rake db:seed` to populate database with sample data

### 8. Run the application

* In app directory run `RAILS_ENV=development rails server`

# Steps to run test

* Within app directory run `RAILS_ENV=testing bundle exec rspec --format documentation`

# Troubleshooting

-