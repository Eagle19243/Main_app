require 'rack/rewrite'
require ::File.expand_path('../config/environment', __FILE__)

use Rack::Rewrite do
  r301 %r{.*}, 'https://staging.weserve.io$&', :scheme => 'http', :if => Proc.new {|rack_env|
    Rails.env.staging?
  }

  r301 %r{.*}, 'https://weserve.io$&', :scheme => 'http', :if => Proc.new {|rack_env|
    Rails.env.production?
  }
end

run Rails.application
