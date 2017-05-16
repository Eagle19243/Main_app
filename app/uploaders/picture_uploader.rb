# encoding: utf-8

class PictureUploader < CarrierWave::Uploader::Base

  include CarrierWave::MiniMagick
  process resize_to_fit: [400, 400]

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
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
