# encoding: utf-8

class PictureUploader < CarrierWave::Uploader::Base

  include CarrierWave::MiniMagick
  process resize_to_fit: [400, 400]

  if Rails.env.production?
    storage :fog
  else
    storage :file
  end

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def default_url(*args)
    "no_image.png"
  end
  
  process crop: :picture

  version :thumb do
    process resize_to_fit: [50, 50]
  end

  version :medium do
    process resize_to_fill: [535, 350]
  end

  def extension_white_list
    %w(jpg jpeg gif png)
  end
end
