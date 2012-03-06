require 'test_helper'

class TneInvoicesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:tne_invoices)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create tne_invoice" do
    assert_difference('TneInvoice.count') do
      post :create, :tne_invoice => { }
    end

    assert_redirected_to tne_invoice_path(assigns(:tne_invoice))
  end

  test "should show tne_invoice" do
    get :show, :id => tne_invoices(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => tne_invoices(:one).to_param
    assert_response :success
  end

  test "should update tne_invoice" do
    put :update, :id => tne_invoices(:one).to_param, :tne_invoice => { }
    assert_redirected_to tne_invoice_path(assigns(:tne_invoice))
  end

  test "should destroy tne_invoice" do
    assert_difference('TneInvoice.count', -1) do
      delete :destroy, :id => tne_invoices(:one).to_param
    end

    assert_redirected_to tne_invoices_path
  end
end
