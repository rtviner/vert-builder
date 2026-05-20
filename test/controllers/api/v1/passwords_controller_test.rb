require "test_helper"

class Api::V1::PasswordsControllerTest < ActionDispatch::IntegrationTest
  test "should allow updating password" do
    patch api_v1_password_url(sessions(:one)), params: { current_password: "password", new_password: "newpassword", new_password_confirmation: "newpassword" }, headers: { "Authorization" => "Bearer #{sessions(:one).auth_token}" }
    assert_response :success
  end

  test "should destroy session on password update" do
    patch api_v1_password_url(sessions(:one)), params: { current_password: "password", new_password: "newpassword", new_password_confirmation: "newpassword" }, headers: { "Authorization" => "Bearer #{sessions(:one).auth_token}" }
    assert_response :success

    assert_nil Current.session
    get api_v1_session_url, headers: { "Authorization" => "Bearer #{sessions(:one).auth_token}" }
    assert_response :not_found
  end

  test "should not allow user with invalid password to reset password" do
    patch api_v1_password_url(sessions(:one)), params: { current_password: "wrongpassword", new_password: "newpassword", new_password_confirmation: "newpassword" }, headers: { "Authorization" => "Bearer #{sessions(:one).auth_token}" }
    assert_response :unauthorized
  end

  test "should not allow user with invalid new password confirmation to reset password" do
    patch api_v1_password_url(sessions(:one)), params: { current_password: "password", new_password: "newpassword", new_password_confirmation: "mismatch" }, headers: { "Authorization" => "Bearer #{sessions(:one).auth_token}" }
    assert_response :unprocessable_entity
  end
end
