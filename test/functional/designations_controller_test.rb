require 'test_helper'

class DesignationsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:designations)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create designation" do
    assert_difference('Designation.count') do
      post :create, :designation => { }
    end

    assert_redirected_to designation_path(assigns(:designation))
  end

  test "should show designation" do
    get :show, :id => designations(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => designations(:one).to_param
    assert_response :success
  end

  test "should update designation" do
    put :update, :id => designations(:one).to_param, :designation => { }
    assert_redirected_to designation_path(assigns(:designation))
  end

  test "should destroy designation" do
    assert_difference('Designation.count', -1) do
      delete :destroy, :id => designations(:one).to_param
    end

    assert_redirected_to designations_path
  end
end
