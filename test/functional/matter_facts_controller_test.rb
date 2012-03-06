require 'test_helper'

class MatterFactsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:matter_facts)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create matter_fact" do
    assert_difference('MatterFact.count') do
      post :create, :matter_fact => { }
    end

    assert_redirected_to matter_fact_path(assigns(:matter_fact))
  end

  test "should show matter_fact" do
    get :show, :id => matter_facts(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => matter_facts(:one).to_param
    assert_response :success
  end

  test "should update matter_fact" do
    put :update, :id => matter_facts(:one).to_param, :matter_fact => { }
    assert_redirected_to matter_fact_path(assigns(:matter_fact))
  end

  test "should destroy matter_fact" do
    assert_difference('MatterFact.count', -1) do
      delete :destroy, :id => matter_facts(:one).to_param
    end

    assert_redirected_to matter_facts_path
  end
end
