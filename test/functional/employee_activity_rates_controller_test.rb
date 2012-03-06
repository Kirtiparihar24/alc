require 'test_helper'

class EmployeeActivityRatesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:employee_activity_rates)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create employee_activity_rate" do
    assert_difference('EmployeeActivityRate.count') do
      post :create, :employee_activity_rate => { }
    end

    assert_redirected_to employee_activity_rate_path(assigns(:employee_activity_rate))
  end

  test "should show employee_activity_rate" do
    get :show, :id => employee_activity_rates(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => employee_activity_rates(:one).to_param
    assert_response :success
  end

  test "should update employee_activity_rate" do
    put :update, :id => employee_activity_rates(:one).to_param, :employee_activity_rate => { }
    assert_redirected_to employee_activity_rate_path(assigns(:employee_activity_rate))
  end

  test "should destroy employee_activity_rate" do
    assert_difference('EmployeeActivityRate.count', -1) do
      delete :destroy, :id => employee_activity_rates(:one).to_param
    end

    assert_redirected_to employee_activity_rates_path
  end
end
