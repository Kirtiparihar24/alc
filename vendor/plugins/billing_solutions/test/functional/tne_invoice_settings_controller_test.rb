require 'test_helper'

class TneInvoiceSettingsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:tne_invoice_settings)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create tne_invoice_setting" do
    assert_difference('TneInvoiceSetting.count') do
      post :create, :tne_invoice_setting => { }
    end

    assert_redirected_to tne_invoice_setting_path(assigns(:tne_invoice_setting))
  end

  test "should show tne_invoice_setting" do
    get :show, :id => tne_invoice_settings(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => tne_invoice_settings(:one).to_param
    assert_response :success
  end

  test "should update tne_invoice_setting" do
    put :update, :id => tne_invoice_settings(:one).to_param, :tne_invoice_setting => { }
    assert_redirected_to tne_invoice_setting_path(assigns(:tne_invoice_setting))
  end

  test "should destroy tne_invoice_setting" do
    assert_difference('TneInvoiceSetting.count', -1) do
      delete :destroy, :id => tne_invoice_settings(:one).to_param
    end

    assert_redirected_to tne_invoice_settings_path
  end
end
