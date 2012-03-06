require 'test_helper'

class MattersControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:matters)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create matter" do
    assert_difference('Matter.count') do
      post :create, :matter => { }
    end

    assert_redirected_to matter_path(assigns(:matter))
  end

  test "should show matter" do
    get :show, :id => matters(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => matters(:one).to_param
    assert_response :success
  end

  test "should update matter" do
    put :update, :id => matters(:one).to_param, :matter => { }
    assert_redirected_to matter_path(assigns(:matter))
  end

  test "should destroy matter" do
    assert_difference('Matter.count', -1) do
      delete :destroy, :id => matters(:one).to_param
    end

    assert_redirected_to matters_path
  end
end
