require "test_helper"

class Api::V1::PlansControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:one)
  end
  test "creates a new plan for the current user" do
    assert_changes -> { Plan.count } do
      post api_v1_plans_url, params: {
        plan: {
          baseline_vertical_distance: 1000,
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

  test "propagates errors when day generation fails" do
    assert_no_difference("Plan.count") do
      post api_v1_plans_url, params: {
        plan: {
          baseline_vertical_distance: 1000,
          baseline_duration: 180,
          goal_vertical_distance: 3300,
          vertical_build_percentage: 5
        }
      },
      headers: auth_headers(@user)
    end
    assert_response :unprocessable_entity
    assert_includes response.body, "Day generation failed: could not distribute total 250.0 across 5 items"
  end
  test "creates a new plan for the current user with a high goal vertical distance" do
    assert_changes -> { Plan.count } do
      post api_v1_plans_url, params: {
        plan: {
          baseline_vertical_distance: 1624,
          baseline_duration: 180,
          goal_vertical_distance: 15000,
          vertical_build_percentage: 10
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

  test "index returns all plans for the current user" do
    active_plan = plans(:user_one_active)
    planned_plan = plans(:user_one_planned)

    get api_v1_plans_path, headers: auth_headers(@user)

    assert_response :success
    ids = JSON.parse(response.body).map { |p| p["id"] }

    assert_includes ids, active_plan.id
    assert_includes ids, planned_plan.id
  end

  test "index filters plans by status" do
    active_plan = plans(:user_one_active)
    planned_plan = plans(:user_one_planned)

    get api_v1_plans_path, params: { status: "active" },
      headers: auth_headers(@user)

    assert_response :success
    body = JSON.parse(response.body)
    ids = body.map { |p| p["id"] }
    assert_includes ids, active_plan.id
    refute_includes ids, planned_plan.id
    assert(body.all? { |p| p["status"] == "active" })
  end

  test "index returns 422 for an invalid status filter" do
    get api_v1_plans_path, params: { status: "bogus" },
      headers: auth_headers(@user)

    assert_response :unprocessable_entity
    body = JSON.parse(response.body)
    assert_equal "Validation failed", body["error"]["message"]
  end

  test "index returns only current users plan" do
    other_users_plan = plans(:user_two_active)  # belongs to a different user

    get api_v1_plans_path, headers: auth_headers(@user)

    assert_response :success
    ids = JSON.parse(response.body).map { |p| p["id"] }
    refute_includes ids, other_users_plan.id
  end

  test "index returns an empty array when the user has no plans matching the status" do
    get api_v1_plans_path, params: { status: "abandoned" },
      headers: auth_headers(users(:two))

    assert_response :success
    assert_equal [], JSON.parse(response.body)
  end

  test "index requires authentication" do
    get api_v1_plans_path
    assert_response :unauthorized
  end

  test "show returns a specific plan with its weeks and days" do
    plan = plans(:user_two_active)

    get api_v1_plan_path(plan), headers: auth_headers(users(:two))

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal plan.id, body["id"]
    assert body.key?("weeks")
    assert body["weeks"].is_a?(Array)
  end

  test "show returns nested days for each week" do
    plan = plans(:user_two_active)

    get api_v1_plan_path(plan), headers: auth_headers(users(:two))

    body = JSON.parse(response.body)
    body["weeks"].each do |week|
      assert week.key?("days")
      assert week["days"].is_a?(Array)
      assert_equal 7, week["days"].size
    end
  end
  test "show returns weeks in week_number order" do
    plan = plans(:user_two_active)

    get api_v1_plan_path(plan), headers: auth_headers(users(:two))

    body = JSON.parse(response.body)
    week_numbers = body["weeks"].map { |w| w["week_number"] }
    assert_equal week_numbers.sort, week_numbers
  end

  test "show returns days in position order" do
    plan = plans(:user_two_active)

    get api_v1_plan_path(plan), headers: auth_headers(users(:two))

    body = JSON.parse(response.body)
    body["weeks"].each do |week|
      positions = week["days"].map { |d| d["position"] }
      assert_equal positions.sort, positions
    end
  end

  test "show returns 404 for another user's plan" do
    other_users_plan = plans(:user_two_active)

    get api_v1_plan_path(other_users_plan), headers: auth_headers(@user)

    assert_response :not_found
  end

  test "show returns 404 for a nonexistent plan id" do
    get api_v1_plan_path(id: 0), headers: auth_headers(@user)

    assert_response :not_found
  end

  test "show requires authentication" do
    plan = plans(:user_one_planned)

    get api_v1_plan_path(plan)

    assert_response :unauthorized
  end
end
