require 'test_helper'

class StaticPagesControllerTest < ActionController::TestCase
  test "should get home" do
    get :home
    assert_response :success
  end

  test "should get about" do
    get :about
    assert_response :success
  end

  test "should get contact" do
    get :contact
    assert_response :success
  end

  test "should get services" do
    get :services
    assert_response :success
  end

  test "should get invest" do
    get :invest
    assert_response :success
  end

  test "should get live" do
    get :live
    assert_response :success
  end

  test "should get ourteam" do
    get :ourteam
    assert_response :success
  end

  test "should get news" do
    get :news
    assert_response :success
  end

end
