require 'test_helper'

class MatterResearchesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:matter_researches)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create matter_research" do
    assert_difference('MatterResearch.count') do
      post :create, :matter_research => { }
    end

    assert_redirected_to matter_research_path(assigns(:matter_research))
  end

  test "should show matter_research" do
    get :show, :id => matter_researches(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => matter_researches(:one).to_param
    assert_response :success
  end

  test "should update matter_research" do
    put :update, :id => matter_researches(:one).to_param, :matter_research => { }
    assert_redirected_to matter_research_path(assigns(:matter_research))
  end

  test "should destroy matter_research" do
    assert_difference('MatterResearch.count', -1) do
      delete :destroy, :id => matter_researches(:one).to_param
    end

    assert_redirected_to matter_researches_path
  end
end
