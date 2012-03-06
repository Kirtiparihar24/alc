require 'test_helper'

class ProductLicenceDetailsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:product_licence_details)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create product_licence_detail" do
    assert_difference('ProductLicenceDetail.count') do
      post :create, :product_licence_detail => { }
    end

    assert_redirected_to product_licence_detail_path(assigns(:product_licence_detail))
  end

  test "should show product_licence_detail" do
    get :show, :id => product_licence_details(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => product_licence_details(:one).to_param
    assert_response :success
  end

  test "should update product_licence_detail" do
    put :update, :id => product_licence_details(:one).to_param, :product_licence_detail => { }
    assert_redirected_to product_licence_detail_path(assigns(:product_licence_detail))
  end

  test "should destroy product_licence_detail" do
    assert_difference('ProductLicenceDetail.count', -1) do
      delete :destroy, :id => product_licence_details(:one).to_param
    end

    assert_redirected_to product_licence_details_path
  end
end
