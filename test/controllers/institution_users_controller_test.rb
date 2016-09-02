require 'test_helper'

class InstitutionUsersControllerTest < ActionController::TestCase
  setup do
    @institution_user = institution_users(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:institution_users)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create institution_user" do
    assert_difference('InstitutionUser.count') do
      post :create, institution_user: { institution_id: @institution_user.institution_id, position: @institution_user.position, user_id: @institution_user.user_id }
    end

    assert_redirected_to institution_user_path(assigns(:institution_user))
  end

  test "should show institution_user" do
    get :show, id: @institution_user
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @institution_user
    assert_response :success
  end

  test "should update institution_user" do
    patch :update, id: @institution_user, institution_user: { institution_id: @institution_user.institution_id, position: @institution_user.position, user_id: @institution_user.user_id }
    assert_redirected_to institution_user_path(assigns(:institution_user))
  end

  test "should destroy institution_user" do
    assert_difference('InstitutionUser.count', -1) do
      delete :destroy, id: @institution_user
    end

    assert_redirected_to institution_users_path
  end
end
