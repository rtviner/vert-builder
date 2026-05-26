require "test_helper"

class PlanTest < ActiveSupport::TestCase
  def setup
    @plan = Plan.new(parent: users(:one), baseline_vertical_distance: 100, baseline_duration: 60, goal_vertical_distance: 200, recovery_pattern: 0, vertical_build_percentage: 10, status: 0)
  end

  test "valid plan" do
    assert @plan.valid?
  end

  test "invalid without required fields" do
    @plan.baseline_vertical_distance = nil
    assert_not @plan.valid?
    assert_includes @plan.errors[:baseline_vertical_distance], "can't be blank"
  end

  test "vertical_build_percentage within range" do
    @plan.vertical_build_percentage = 20
    assert_not @plan.valid?
    assert_includes @plan.errors[:vertical_build_percentage], "must be less than or equal to #{Plan::MAX_BUILD_PERCENTAGE}"
  end

  test "goal_vertical_distance greater than baseline" do
    @plan.goal_vertical_distance = 50
    @plan.baseline_vertical_distance = 100
    assert_not @plan.valid?
    assert_includes @plan.errors[:goal_vertical_distance], "must be greater than 100"
  end

  test "enums are defined" do
    assert Plan.statuses.keys.include?("planned")
    assert Plan.recovery_pattern.keys.include?("every_other")
  end

  test "progress_percentage returns 0 with no weeks" do
    assert_equal 0, @plan.progress_percentage
  end
end
