require 'test_helper'

class CompanyActivityRatesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:company_activity_rates)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create company_activity_rate" do
    assert_difference('CompanyActivityRate.count') do
      post :create, :company_activity_rate => { }
    end

    assert_redirected_to company_activity_rate_path(assigns(:company_activity_rate))
  end

  test "should show company_activity_rate" do
    get :show, :id => company_activity_rates(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => company_activity_rates(:one).to_param
    assert_response :success
  end

  test "should update company_activity_rate" do
    put :update, :id => company_activity_rates(:one).to_param, :company_activity_rate => { }
    assert_redirected_to company_activity_rate_path(assigns(:company_activity_rate))
  end

  test "should destroy company_activity_rate" do
    assert_difference('CompanyActivityRate.count', -1) do
      delete :destroy, :id => company_activity_rates(:one).to_param
    end

    assert_redirected_to company_activity_rates_path
  end
end
