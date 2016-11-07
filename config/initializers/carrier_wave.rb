CarrierWave.configure do |config|

  # Use local storage if in development or test
  if Rails.env.development? || Rails.env.test?
    CarrierWave.configure do |config|
      config.storage = :file
    end
  end

  # Use AWS storage if in production
  if Rails.env.production?
    CarrierWave.configure do |config|
      config.storage = :fog
    end
  end

  config.fog_credentials = {
    :provider               => 'AWS',                             # required
    # :aws_access_key_id      => 'AKIAJAB7DXYNQS2GQZJA',            # required
    # :aws_secret_access_key  => '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',     # required
    :aws_access_key_id      => 'AKIAJ3YZVD3AAH4PPZUQ',            # required
    :aws_secret_access_key  => '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',     # required
    :region                 => 'us-west-2'                        # optional, defaults to 'us-east-1'
  }
  config.fog_directory  = 'youserve'               # required

end
