require "test_helper"

class Api::V1::SessionsTest < ActionDispatch::IntegrationTest
  fixtures :users
  fixtures :sessions

  test "should log in with valid credentials" do
    post api_v1_session_url, params: { email_address: users(:one).email_address, password: "password" }
    assert_response :created
  end

  test "should not create session with invalid credentials" do
    post api_v1_session_url, params: { email_address: users(:one).email_address, password: "wrongpass" }
    assert_response :unauthorized
    assert_equal "Invalid email address or password", JSON.parse(response.body)["error"]
  end

  test "should destroy session" do
    assert_changes -> { Session.count }, from: 2, to: 1 do
      delete api_v1_session_url, headers: { "Authorization" => "Bearer #{sessions(:one).auth_token}" }
    end
    assert_nil Current.session
    assert_response :success
    assert_equal "logged out", JSON.parse(response.body)["message"]
  end

  test "should not destroy session with invalid token" do
    delete api_v1_session_url, headers: { "Authorization" => "Bearer invalid" }
    assert_response :unauthorized
  end
end
