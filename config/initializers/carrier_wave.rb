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
    :provider               => 'AWS',
    :aws_access_key_id      => 'AKIAICHATLPPRDAIHS7Q', #AKIAIK5Q7ZUBDPHFWI6A
    :aws_secret_access_key  => '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', #Lnt9O8f2dGFBnLv7dxlrvJKxpFDmIr3HwPtfcRhc
    :region                 => 'us-east-1'
  }

  config.fog_directory  = 'youserve'

end
