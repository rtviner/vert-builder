require "test_helper"

class Api::V1::PlansControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:one)
  end
  test "create a new plan for the current user" do
    assert_changes -> { Plan.count } do
      post api_v1_plans_url, params: {
        plan: {
          baseline_vertical_distance: 1624,
          baseline_duration: 180,
          goal_vertical_distance: 3300,
          vertical_build_percentage: 10
        }
      },
      headers: auth_headers(@user)
    end
    assert_response :success
  end

  test "creates a new plan for the current user with chosen recovery pattern" do
    assert_changes -> { Plan.count } do
      post api_v1_plans_url, params: {
        plan: {
          baseline_vertical_distance: 1624,
          baseline_duration: 180,
          goal_vertical_distance: 3300,
          vertical_build_percentage: 10,
          recovery_pattern: :every_fourth
        }
      },
      headers: auth_headers(@user)
    end
    assert_response :success
  end

  test "creates a new plan for the current user with flexible end date" do
    assert_changes -> { Plan.count } do
      post api_v1_plans_url, params: {
        plan: {
          baseline_vertical_distance: 1624,
          baseline_duration: 180,
          goal_vertical_distance: 3300,
          vertical_build_percentage: 10,
          flexible_end_date: true,
          start_date: Date.today,
          end_date: Date.today + 12.weeks
        }
      },
      headers: auth_headers(@user)
    end
    assert_response :success
  end

  test "returns an error when plan creation fails" do
    assert_no_difference("Plan.count") do
      post api_v1_plans_url, params: {
        plan: {
          baseline_vertical_distance: nil,
          baseline_duration: 180,
          goal_vertical_distance: 3300,
          vertical_build_percentage: 10
        }
      },
      headers: auth_headers(@user)
    end
    assert_response :unprocessable_entity
  end

  test "should not create a plan without a goal_vertical_distance" do
    assert_no_difference("Plan.count") do
      post api_v1_plans_url, params: {
        plan: {
          baseline_vertical_distance: 1624,
          baseline_duration: 180,
          goal_vertical_distance: nil,
          goal_duration: 0,
          recovery_pattern: :every_other,
          vertical_build_percentage: 10,
          flexible_end_date: true,
          start_date: Date.today,
          end_date: Date.today + 12.weeks
        }
      },
      headers: auth_headers(@user)
    end
    assert_response :unprocessable_entity
  end
end
