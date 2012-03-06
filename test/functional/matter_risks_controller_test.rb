require 'test_helper'

class MatterRisksControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:matter_risks)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create matter_risk" do
    assert_difference('MatterRisk.count') do
      post :create, :matter_risk => { }
    end

    assert_redirected_to matter_risk_path(assigns(:matter_risk))
  end

  test "should show matter_risk" do
    get :show, :id => matter_risks(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => matter_risks(:one).to_param
    assert_response :success
  end

  test "should update matter_risk" do
    put :update, :id => matter_risks(:one).to_param, :matter_risk => { }
    assert_redirected_to matter_risk_path(assigns(:matter_risk))
  end

  test "should destroy matter_risk" do
    assert_difference('MatterRisk.count', -1) do
      delete :destroy, :id => matter_risks(:one).to_param
    end

    assert_redirected_to matter_risks_path
  end
end
