class Content < ActiveRecord::Base
  attr_accessible :body, :link, :title


  #home page scopes
  scope :home_heading, where("title = 'home_heading'")
  scope :home_right_sidebar, where("title = 'home_right_sidebar'")

  #about page scopes

  scope :about_heading, where("title = 'about_heading'")
  scope :about_right_sidebar, where("title = 'about_right_sidebar'")
  scope :about_team, where("title = 'about_team'")
  scope :about_contactus, where("title = 'about_contactus'")
  scope :about_portfolio, where("title = 'about_portfolio'")
  scope :about_about, where("title = 'about_about'")


  #wuxi page scopes

  scope :wuxi_invest, where("title = 'wuxi_invest'")
  scope :wuxi_wuxi, where("title = 'wuxi_wuxi'")
  scope :wuxi_living, where("title = 'wuxi_living'")


  #services page scopes

  scope :services_info, where("title = 'services_info'")
  scope :services_explore, where("title = 'services_explore'")
  scope :services_invest, where("title = 'services_invest'")
  scope :services_relocate, where("title = 'services_relocate'")
  scope :services_management, where("title = 'services_management'")

  #contact_us page scopes
  scope :contactus_main, where("title = 'contactus_main'")

  #heading

  scope :header_brand, where("title = 'header_brand'")

  #sidebars

  scope :home_sidebar, where("title = 'home_sidebar'")
  scope :about_sidebar, where("title = 'about_sidebar'")
  scope :wuxi_sidebar, where("title = 'wuxi_sidebar'")
  scope :services_sidebar, where("title = 'services_sidebar'")
  scope :contactus_sidebar, where("title = 'contactus_sidebar'")

end
