# encoding: utf-8

class PictureUploader < CarrierWave::Uploader::Base

  # Include RMagick or MiniMagick support:
  include CarrierWave::RMagick
  # include CarrierWave::MiniMagick

  # Include the Sprockets helpers for Rails 3.1+ asset pipeline compatibility:
  # include Sprockets::Helpers::RailsHelper
  # include Sprockets::Helpers::IsolatedHelper

  # Choose what kind of storage to use for this uploader:
  storage :file
  # storage :fog

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  # def default_url
  #   # For Rails 3.1+ asset pipeline compatibility:
  #   # asset_path("fallback/" + [version_name, "default.png"].compact.join('_'))
  #
  #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')

  # version :thumb do
  #   process :scale => [50(width), 50(height)]
  # end
  # end
  process :auto_orient
  process resize_to_fit: [1280, 1280]

  version :medium do
    process :auto_orient
    process resize_to_fit: [600, 600]
  end
  version :slider, from_version: :medium do
    process :auto_orient
    process resize_and_pad: [500, 600, background='#cfd4d8']
  end
  version :slider_big do
    process :auto_orient
    process resize_and_pad: [800, 800, background='#cfd4d8']
  end
  version :thumb, from_version: :medium  do
    process :auto_orient
    process resize_to_fill: [100,100]
  end
  version :mini, from_version: :thumb  do
    process :auto_orient
    process resize_to_limit: [40,40]
  end

  # Auto-orient image to respect rotation flag
  def auto_orient
    manipulate! do |img|
      img = img.auto_orient
    end
  end

  # Process files as they are uploaded:
  # process :scale => [200, 300]
  #
  # def scale(width, height)
  #   # do something
  # end

  # Create different versions of your uploaded files:
  # version :thumb do
  #   process :scale => [50, 50]
  # end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
    %w(jpg jpeg gif png bmp svg)
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.jpg" if original_filename
  # end

end
