CarrierWave.configure do |config|

  # Use local storage if in development or test
  if Rails.env.development? || Rails.env.test?
    CarrierWave.configure do |config|
      config.storage = :file
    end
  end

  if Rails.env.production?
    CarrierWave.configure do |config|
      config.storage = :fog
    end
  end

  config.fog_credentials = {
    :provider               => ENV["service_provider"],
    :aws_access_key_id      => ENV["aws_access_key_id"],
    :aws_secret_access_key  => ENV["aws_secret_access_key"],
    :region                 => ENV["s3_bucket_region"]
  }

  config.fog_directory  = ENV["bucket_name"]

end
