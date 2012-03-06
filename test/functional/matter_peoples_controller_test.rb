require 'test_helper'

class MatterPeoplesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:matter_peoples)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create matter_people" do
    assert_difference('MatterPeople.count') do
      post :create, :matter_people => { }
    end

    assert_redirected_to matter_people_path(assigns(:matter_people))
  end

  test "should show matter_people" do
    get :show, :id => matter_peoples(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => matter_peoples(:one).to_param
    assert_response :success
  end

  test "should update matter_people" do
    put :update, :id => matter_peoples(:one).to_param, :matter_people => { }
    assert_redirected_to matter_people_path(assigns(:matter_people))
  end

  test "should destroy matter_people" do
    assert_difference('MatterPeople.count', -1) do
      delete :destroy, :id => matter_peoples(:one).to_param
    end

    assert_redirected_to matter_peoples_path
  end
end
