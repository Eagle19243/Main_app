#!/bin/bash
cd /home/ubuntu/appname/
echo "cd executed" /home/ubuntu/log
RAILS_ENV=production bundle exec rake db:migrate
echo "rake executed" /home/ubuntu/log
RAILS_ENV=production bundle exec rake db:seed
echo "rake db:seed executed" /home/ubuntu/log
RAILS_ENV=production bundle exec rake assets:precompile
echo "rake precompile executed" /home/ubuntu/log
bundle install
echo " bundle executed" /home/ubuntu/log
