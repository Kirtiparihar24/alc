require 'test_helper'

class TneInvoiceDetailsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:tne_invoice_details)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create tne_invoice_detail" do
    assert_difference('TneInvoiceDetail.count') do
      post :create, :tne_invoice_detail => { }
    end

    assert_redirected_to tne_invoice_detail_path(assigns(:tne_invoice_detail))
  end

  test "should show tne_invoice_detail" do
    get :show, :id => tne_invoice_details(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => tne_invoice_details(:one).to_param
    assert_response :success
  end

  test "should update tne_invoice_detail" do
    put :update, :id => tne_invoice_details(:one).to_param, :tne_invoice_detail => { }
    assert_redirected_to tne_invoice_detail_path(assigns(:tne_invoice_detail))
  end

  test "should destroy tne_invoice_detail" do
    assert_difference('TneInvoiceDetail.count', -1) do
      delete :destroy, :id => tne_invoice_details(:one).to_param
    end

    assert_redirected_to tne_invoice_details_path
  end
end
