class ApplicationController < ActionController::Base
  protect_from_forgery
  include SessionsHelper

  before_filter :define_instance

  def define_instance
    @header_brand= Content.header_brand.last
    @contactus_sidebar= Content.contactus_sidebar.last

  end



  # Force signout to prevent CSRF attacks
  def handle_unverified_request
    sign_out
    super
  end

end