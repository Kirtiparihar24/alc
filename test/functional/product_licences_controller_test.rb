require 'test_helper'

class ProductLicencesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:product_licences)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create product_licence" do
    assert_difference('ProductLicence.count') do
      post :create, :product_licence => { }
    end

    assert_redirected_to product_licence_path(assigns(:product_licence))
  end

  test "should show product_licence" do
    get :show, :id => product_licences(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => product_licences(:one).to_param
    assert_response :success
  end

  test "should update product_licence" do
    put :update, :id => product_licences(:one).to_param, :product_licence => { }
    assert_redirected_to product_licence_path(assigns(:product_licence))
  end

  test "should destroy product_licence" do
    assert_difference('ProductLicence.count', -1) do
      delete :destroy, :id => product_licences(:one).to_param
    end

    assert_redirected_to product_licences_path
  end
end
