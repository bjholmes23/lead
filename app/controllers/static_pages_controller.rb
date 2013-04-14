class StaticPagesController < ApplicationController

  layout :resolve_layout

  def resolve_layout
    case action_name
      when "home"
        "home"
      else
        "application"
    end
  end



  def home

    @home_heading = Content.home_heading.last
    @home_right_sidebar = Content.home_right_sidebar.last

    l = Slider.order("position")
    @sliders = l.drop(1)
    @first_slider = l.first
    @mini_dimension = "100"


  end

  def about
    @about_heading = Content.about_heading.last
    @about_right_sidebar = Content.about_right_sidebar.last
    @about_team= Content.about_team.last
    @about_contactus= Content.about_contactus.last
    @about_portfolio= Content.about_portfolio.last
    @about_about= Content.about_about.last

  end


  def services
    @services_explore= Content.services_explore.last
    @services_invest= Content.services_invest.last
    @services_relocate= Content.services_relocate.last
    @services_management= Content.services_management.last
  end

  def invest
    @wuxi_invest= Content.wuxi_invest.last
    @wuxi_wuxi= Content.wuxi_wuxi.last
    @wuxi_living= Content.wuxi_living.last

  end

  def live
  end

  def ourteam
  end

  def news
  end
end
