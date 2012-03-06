require 'test_helper'

class LitigationsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:litigations)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create litigation" do
    assert_difference('Litigation.count') do
      post :create, :litigation => { }
    end

    assert_redirected_to litigation_path(assigns(:litigation))
  end

  test "should show litigation" do
    get :show, :id => litigations(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => litigations(:one).to_param
    assert_response :success
  end

  test "should update litigation" do
    put :update, :id => litigations(:one).to_param, :litigation => { }
    assert_redirected_to litigation_path(assigns(:litigation))
  end

  test "should destroy litigation" do
    assert_difference('Litigation.count', -1) do
      delete :destroy, :id => litigations(:one).to_param
    end

    assert_redirected_to litigations_path
  end
end
