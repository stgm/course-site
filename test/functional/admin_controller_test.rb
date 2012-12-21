require 'test_helper'

class AdminControllerTest < ActionController::TestCase
  test "should get import" do
    get :import
    assert_response :success
  end

  test "should get import_do" do
    get :import_do
    assert_response :success
  end

end
