require "test_helper"

class Api::V1::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "should create a new user" do
    assert_changes -> { User.count } do
      post api_v1_registrations_url, params: {
        user: {
          email_address: "test@example.com",
          password: "password",
          password_confirmation: "password"
        }
      }
    end

    assert_response :created
  end

  test "should not create a user with invalid parameters" do
    assert_no_difference("User.count") do
      post api_v1_registrations_url, params: {
        user: {
          email_address: "invalid_email",
          password: "password",
          password_confirmation: "password"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should not create a user with non-matching password confirmation" do
    assert_no_difference("User.count") do
      post api_v1_registrations_url, params: {
        user: {
          email_address: "test@example.com",
          password: "password",
          password_confirmation: "wrong_password"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should not create a user with duplicate email" do
    User.create!(
      email_address: "test@example.com",
      password: "password",
      password_confirmation: "password"
    )

    assert_no_difference("User.count") do
      post api_v1_registrations_url, params: {
        user: {
          email_address: "test@example.com",
          password: "password",
          password_confirmation: "password"
        }
      }
    end

    assert_response :unprocessable_content
  end
end
