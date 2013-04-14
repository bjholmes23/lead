require 'test_helper'

class SlidersControllerTest < ActionController::TestCase
  setup do
    @slider = sliders(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:sliders)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create slider" do
    assert_difference('Slider.count') do
      post :create, slider: { body: @slider.body, link: @slider.link, picture: @slider.picture, shortbody: @slider.shortbody, title: @slider.title }
    end

    assert_redirected_to slider_path(assigns(:slider))
  end

  test "should show slider" do
    get :show, id: @slider
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @slider
    assert_response :success
  end

  test "should update slider" do
    put :update, id: @slider, slider: { body: @slider.body, link: @slider.link, picture: @slider.picture, shortbody: @slider.shortbody, title: @slider.title }
    assert_redirected_to slider_path(assigns(:slider))
  end

  test "should destroy slider" do
    assert_difference('Slider.count', -1) do
      delete :destroy, id: @slider
    end

    assert_redirected_to sliders_path
  end
end
