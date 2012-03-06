require 'test_helper'

class ZimbraActivitiesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:zimbra_activities)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create zimbra_activity" do
    assert_difference('ZimbraActivity.count') do
      post :create, :zimbra_activity => { }
    end

    assert_redirected_to zimbra_activity_path(assigns(:zimbra_activity))
  end

  test "should show zimbra_activity" do
    get :show, :id => zimbra_activities(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => zimbra_activities(:one).to_param
    assert_response :success
  end

  test "should update zimbra_activity" do
    put :update, :id => zimbra_activities(:one).to_param, :zimbra_activity => { }
    assert_redirected_to zimbra_activity_path(assigns(:zimbra_activity))
  end

  test "should destroy zimbra_activity" do
    assert_difference('ZimbraActivity.count', -1) do
      delete :destroy, :id => zimbra_activities(:one).to_param
    end

    assert_redirected_to zimbra_activities_path
  end
end
