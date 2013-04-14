class Slider < ActiveRecord::Base


  acts_as_list

  attr_accessible :body, :link, :picture, :shortbody, :title

  mount_uploader :picture, PictureUploader


end
