require 'test_helper'

class DocumentHomesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:document_homes)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create document_home" do
    assert_difference('DocumentHome.count') do
      post :create, :document_home => { }
    end

    assert_redirected_to document_home_path(assigns(:document_home))
  end

  test "should show document_home" do
    get :show, :id => document_homes(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => document_homes(:one).to_param
    assert_response :success
  end

  test "should update document_home" do
    put :update, :id => document_homes(:one).to_param, :document_home => { }
    assert_redirected_to document_home_path(assigns(:document_home))
  end

  test "should destroy document_home" do
    assert_difference('DocumentHome.count', -1) do
      delete :destroy, :id => document_homes(:one).to_param
    end

    assert_redirected_to document_homes_path
  end
end
