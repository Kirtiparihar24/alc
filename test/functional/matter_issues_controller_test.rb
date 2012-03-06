require 'test_helper'

class MatterIssuesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:matter_issues)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create matter_issue" do
    assert_difference('MatterIssue.count') do
      post :create, :matter_issue => { }
    end

    assert_redirected_to matter_issue_path(assigns(:matter_issue))
  end

  test "should show matter_issue" do
    get :show, :id => matter_issues(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => matter_issues(:one).to_param
    assert_response :success
  end

  test "should update matter_issue" do
    put :update, :id => matter_issues(:one).to_param, :matter_issue => { }
    assert_redirected_to matter_issue_path(assigns(:matter_issue))
  end

  test "should destroy matter_issue" do
    assert_difference('MatterIssue.count', -1) do
      delete :destroy, :id => matter_issues(:one).to_param
    end

    assert_redirected_to matter_issues_path
  end
end
