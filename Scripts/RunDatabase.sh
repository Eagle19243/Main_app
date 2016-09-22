#!/bin/bash
cd /home/ubuntu/appname
RAILS_ENV=production rake db:migrate
RAILS_ENV=production rake db:seed
RAILS_ENV=production rake assets:precompile
