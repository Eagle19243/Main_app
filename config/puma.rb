workers Integer(ENV['WEB_CONCURRENCY'] || 2)

min_threads_count = Integer(ENV['MIN_THREADS'] || 0)
max_threads_count = Integer(ENV['MAX_THREADS'] || 16)
threads min_threads_count, max_threads_count

preload_app!

rails_env = ENV['RAILS_ENV'] || "production"
environment rails_env

worker_timeout 60

# Set up directory locations
app_dir = File.expand_path("../..",__FILE__)
shared_dir = "#{app_dir}/shared"

# Logging
stdout_redirect "#{app_dir}/log/puma.stdout.log", "#{app_dir}/log/puma.stderr.log", true

before_fork do
  # PumaWorkerKiller.config do |config|
  #   config.ram           = 1024 # mb
  #   config.frequency     = 5    # seconds
  #   config.percent_usage = 0.85
  #   config.rolling_restart_frequency = 8 * 3600 # 8 hours in seconds, or set to false
  # end
  # PumaWorkerKiller.ram = 1024
  # PumaWorkerKiller.start
end

# Set master PID and state locations
pidfile "#{app_dir}/tmp/pids/puma.pid"
state_path "#{app_dir}/tmp/pids/puma.state"
activate_control_app

rackup      DefaultRackup
port        ENV['PORT']     || 3000
environment ENV['RACK_ENV'] || 'development'

on_worker_boot do
  require "active_record"
  ActiveRecord::Base.connection.disconnect! rescue ActiveRecord::ConnectionNotEstablished
  ActiveRecord::Base.establish_connection(ENV["DATABASE_URL"] || YAML.load_file("#{app_dir}/config/database.yml")[rails_env])
end
