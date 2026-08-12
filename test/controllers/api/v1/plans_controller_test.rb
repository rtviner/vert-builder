require "test_helper"

class Api::V1::PlansControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:one)
  end

  test "PATCH activate sets status to active and returns start date" do
    plan = plans(:user_one_planned)

    patch activate_api_v1_plan_path(plan), params: { start_date: "2026-08-03" },
      headers: auth_headers(@user)

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "active", body["status"]
    assert_equal "2026-08-03", body["start_date"]
  end

  test "PATCH activate returns 400 when no start_date param and none on record" do
    plan = plans(:user_one_planned)

    patch activate_api_v1_plan_path(plan), headers: auth_headers(@user)

    assert_response :bad_request
  end

  test "PATCH activate returns 400 for a malformed start_date" do
    plan = plans(:user_one_planned)

    patch activate_api_v1_plan_path(plan), params: { start_date: "not-a-date" },
      headers: auth_headers(@user)

    assert_response :bad_request
  end

  test "PATCH activate returns 422 when plan is already active" do
    plan = plans(:user_one_active)

    patch activate_api_v1_plan_path(plan), params: { start_date: "2026-08-03" },
      headers: auth_headers(@user)

    assert_response :unprocessable_entity
    body = JSON.parse(response.body)
    error = body["error"]
    assert_includes error["message"], "Validation failed"
    assert_includes error["errors"].first, "Event 'activate' cannot transition from 'active'."
  end

  test "PATCH activate returns 404 for another user's plan" do
    other_users_plan = plans(:user_two_planned)

    patch activate_api_v1_plan_path(other_users_plan), params: { start_date: "2026-08-03" },
      headers: auth_headers(@user)

    assert_response :not_found
  end

  test "PATCH activate requires authentication" do
    plan = plans(:user_one_planned)

    patch activate_api_v1_plan_path(plan), params: { start_date: "2026-08-03" }

    assert_response :unauthorized
  end

  test "CREATE creates a new plan for the current user" do
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

  test "CREATE creates a new plan for the current user with chosen recovery pattern" do
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

  test "CREATE propagates errors when day generation fails" do
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
  test "CREATE creates a new plan for the current user with a high goal vertical distance" do
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

  test "CREATE creates a new plan for the current user with flexible end date" do
    assert_changes -> { Plan.count } do
      post api_v1_plans_url, params: {
        plan: {
          baseline_vertical_distance: 1624,
          baseline_duration: 180,
          goal_vertical_distance: 3300,
          vertical_build_percentage: 10,
          flexible_end_date: true,
          start_date: Date.today
        }
      },
      headers: auth_headers(@user)
    end
    assert_response :success
  end

  test "CREATE creates a new plan for the current user with flexible end date false" do
    assert_changes -> { Plan.count } do
      post api_v1_plans_url, params: {
        plan: {
          baseline_vertical_distance: 1624,
          baseline_duration: 180,
          goal_vertical_distance: 3300,
          vertical_build_percentage: 10,
          flexible_end_date: false,
          end_date: Date.today + 20.weeks
        }
      },
      headers: auth_headers(@user)
    end
    assert_response :success
  end

  test "CREATE returns an error when plan creation fails" do
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

  test "CREATE should not create a plan without a goal_vertical_distance" do
    assert_no_difference("Plan.count") do
      post api_v1_plans_url, params: {
        plan: {
          baseline_vertical_distance: 1624,
          baseline_duration: 180,
          goal_vertical_distance: nil,
          goal_duration: 0,
          recovery_pattern: :every_other,
          vertical_build_percentage: 10,
          flexible_end_date: true
        }
      },
      headers: auth_headers(@user)
    end
    assert_response :unprocessable_entity
  end

  test "CREATE should not create a plan without an end date when flexible_end_date is false" do
    assert_no_difference("Plan.count") do
      post api_v1_plans_url, params: {
        plan: {
          baseline_vertical_distance: 1624,
          baseline_duration: 180,
          goal_vertical_distance: nil,
          goal_duration: 0,
          recovery_pattern: :every_other,
          vertical_build_percentage: 10,
          flexible_end_date: false
        }
      },
      headers: auth_headers(@user)
    end
    assert_response :unprocessable_entity
  end

  test "INDEX returns all plans for the current user" do
    active_plan = plans(:user_one_active)
    planned_plan = plans(:user_one_planned)

    get api_v1_plans_path, headers: auth_headers(@user)

    assert_response :success
    ids = JSON.parse(response.body).map { |p| p["id"] }

    assert_includes ids, active_plan.id
    assert_includes ids, planned_plan.id
  end

  test "GET export_csv returns a CSV file with default full format" do
    user = users(:two)
    plan = plans(:user_two_active)

    get export_csv_api_v1_plan_path(plan), headers: auth_headers(user)

    assert_response :success
    assert_equal "text/csv", response.media_type
  end

  test "GET export_csv accepts a weeks format param" do
    user = users(:two)
    plan = plans(:user_two_active)

    get export_csv_api_v1_plan_path(plan), params: { format: "weeks" },
      headers: auth_headers(user)

    assert_response :success
    csv = CSV.parse(response.body)
    assert_equal [ "start", "type", "mi", "planned gain", "gain", "IL", "hours", "planned hours" ], csv.first
  end

  test "GET export_csv accepts a days format param" do
    user = users(:two)
    plan = plans(:user_two_active)

    get export_csv_api_v1_plan_path(plan), params: { format: "days" },
      headers: auth_headers(user)

    assert_response :success
    csv = CSV.parse(response.body)
    assert_equal [ "day", "date", "notes", "Y", "R", "S", "B", "body", "planned gain", "%run", "\"run" ], csv.first
  end

  test "GET export_csv returns 400 for an invalid format param" do
    user = users(:two)
    plan = plans(:user_two_active)

    get export_csv_api_v1_plan_path(plan), params: { format: "bogus" },
      headers: auth_headers(user)

    assert_response :bad_request
  end

  test "GET export_csv sets a filename with the plan id and format" do
    user = users(:two)
    plan = plans(:user_two_active)

    get export_csv_api_v1_plan_path(plan), params: { format: "weeks" },
      headers: auth_headers(user)

    assert_match(/plan_#{plan.id}_weeks_#{Date.today}\.csv/, response.headers["Content-Disposition"])
  end

  test "GET export_csv returns 404 for another user's plan" do
    other_users_plan = plans(:user_two_planned)

    get export_csv_api_v1_plan_path(other_users_plan), headers: auth_headers(@user)

    assert_response :not_found
  end

  test "GET export_csv requires authentication" do
    plan = plans(:user_one_planned)

    get export_csv_api_v1_plan_path(plan)

    assert_response :unauthorized
  end

  test "INDEX filters plans by status" do
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

  test "INDEX returns 422 for an invalid status filter" do
    get api_v1_plans_path, params: { status: "bogus" },
      headers: auth_headers(@user)

    assert_response :unprocessable_entity
    body = JSON.parse(response.body)
    assert_equal "Validation failed", body["error"]["message"]
  end

  test "INDEX returns only current users plan" do
    other_users_plan = plans(:user_two_active)  # belongs to a different user

    get api_v1_plans_path, headers: auth_headers(@user)

    assert_response :success
    ids = JSON.parse(response.body).map { |p| p["id"] }
    refute_includes ids, other_users_plan.id
  end

  test "INDEX returns an empty array when the user has no plans matching the status" do
    get api_v1_plans_path, params: { status: "abandoned" },
      headers: auth_headers(users(:two))

    assert_response :success
    assert_equal [], JSON.parse(response.body)
  end

  test "INDEX requires authentication" do
    get api_v1_plans_path
    assert_response :unauthorized
  end

  test "SHOW returns a specific plan with its weeks and days" do
    plan = plans(:user_two_active)

    get api_v1_plan_path(plan), headers: auth_headers(users(:two))

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal plan.id, body["id"]
    assert body.key?("weeks")
    assert body["weeks"].is_a?(Array)
  end

  test "SHOW returns nested days for each week" do
    plan = plans(:user_two_active)

    get api_v1_plan_path(plan), headers: auth_headers(users(:two))

    body = JSON.parse(response.body)
    body["weeks"].each do |week|
      assert week.key?("days")
      assert week["days"].is_a?(Array)
      assert_equal 7, week["days"].size
    end
  end
  test "SHOW returns weeks in week_number order" do
    plan = plans(:user_two_active)

    get api_v1_plan_path(plan), headers: auth_headers(users(:two))

    body = JSON.parse(response.body)
    week_numbers = body["weeks"].map { |w| w["week_number"] }
    assert_equal week_numbers.sort, week_numbers
  end

  test "SHOW returns days in position order" do
    plan = plans(:user_two_active)

    get api_v1_plan_path(plan), headers: auth_headers(users(:two))

    body = JSON.parse(response.body)
    body["weeks"].each do |week|
      positions = week["days"].map { |d| d["position"] }
      assert_equal positions.sort, positions
    end
  end

  test "SHOW returns 404 for another user's plan" do
    other_users_plan = plans(:user_two_active)

    get api_v1_plan_path(other_users_plan), headers: auth_headers(@user)

    assert_response :not_found
  end

  test "SHOW returns 404 for a nonexistent plan id" do
    get api_v1_plan_path(id: 0), headers: auth_headers(@user)

    assert_response :not_found
  end

  test "SHOW requires authentication" do
    plan = plans(:user_one_planned)

    get api_v1_plan_path(plan)

    assert_response :unauthorized
  end
end
