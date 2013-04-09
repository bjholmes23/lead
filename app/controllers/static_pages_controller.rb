class StaticPagesController < ApplicationController
  def home
    @home_heading = Content.home_heading.last
    @home_right_sidebar = Content.home_right_sidebar.last


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
