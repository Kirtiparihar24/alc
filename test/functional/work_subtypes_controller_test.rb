require 'test_helper'

class WorkSubtypesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:work_subtypes)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create work_subtype" do
    assert_difference('WorkSubtype.count') do
      post :create, :work_subtype => { }
    end

    assert_redirected_to work_subtype_path(assigns(:work_subtype))
  end

  test "should show work_subtype" do
    get :show, :id => work_subtypes(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => work_subtypes(:one).to_param
    assert_response :success
  end

  test "should update work_subtype" do
    put :update, :id => work_subtypes(:one).to_param, :work_subtype => { }
    assert_redirected_to work_subtype_path(assigns(:work_subtype))
  end

  test "should destroy work_subtype" do
    assert_difference('WorkSubtype.count', -1) do
      delete :destroy, :id => work_subtypes(:one).to_param
    end

    assert_redirected_to work_subtypes_path
  end
end
