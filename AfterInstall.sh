#!/bin/bash
cd /home/ubuntu/appname/
bundle install
echo " after install bundle executed" >> /home/ubuntu/log
echo "after install cd executed " >> /home/ubuntu/log
RAILS_ENV=production bundle exec rake db:migrate
echo "after install rake executed" >> /home/ubuntu/log
RAILS_ENV=production bundle exec rake db:seed
echo "after install rake db:seed executed" >> /home/ubuntu/log
RAILS_ENV=production bundle exec rake assets:precompile
echo "after install rake precompile executed" >> /home/ubuntu/log


