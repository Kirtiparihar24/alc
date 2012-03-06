require 'test_helper'

class CompanyRoleRatesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:company_role_rates)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create company_role_rate" do
    assert_difference('CompanyRoleRate.count') do
      post :create, :company_role_rate => { }
    end

    assert_redirected_to company_role_rate_path(assigns(:company_role_rate))
  end

  test "should show company_role_rate" do
    get :show, :id => company_role_rates(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => company_role_rates(:one).to_param
    assert_response :success
  end

  test "should update company_role_rate" do
    put :update, :id => company_role_rates(:one).to_param, :company_role_rate => { }
    assert_redirected_to company_role_rate_path(assigns(:company_role_rate))
  end

  test "should destroy company_role_rate" do
    assert_difference('CompanyRoleRate.count', -1) do
      delete :destroy, :id => company_role_rates(:one).to_param
    end

    assert_redirected_to company_role_rates_path
  end
end
