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
  end

  def contact
  end

  def services
  end

  def invest
  end

  def live
  end

  def ourteam
  end

  def news
  end
end
