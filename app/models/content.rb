class Content < ActiveRecord::Base
  attr_accessible :body, :link, :title


  #home page scopes
  scope :home_heading, where("title = 'home_heading'")
  scope :home_right_sidebar, where("title = 'home_right_sidebar'")

end
