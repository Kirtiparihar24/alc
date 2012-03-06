require 'test_helper'

class MatterTasksControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:matter_tasks)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create matter_task" do
    assert_difference('MatterTask.count') do
      post :create, :matter_task => { }
    end

    assert_redirected_to matter_task_path(assigns(:matter_task))
  end

  test "should show matter_task" do
    get :show, :id => matter_tasks(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => matter_tasks(:one).to_param
    assert_response :success
  end

  test "should update matter_task" do
    put :update, :id => matter_tasks(:one).to_param, :matter_task => { }
    assert_redirected_to matter_task_path(assigns(:matter_task))
  end

  test "should destroy matter_task" do
    assert_difference('MatterTask.count', -1) do
      delete :destroy, :id => matter_tasks(:one).to_param
    end

    assert_redirected_to matter_tasks_path
  end
end
