require "test_helper"

class PlanTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @plan = Plan.new(
      user: @user,
      baseline_vertical_distance: 1000,
      baseline_duration: 120,
      goal_vertical_distance: 2000,
      goal_duration: 240,
      start_date: Date.today,
      end_date: Date.today + 30,
      completed_date: nil,
      flexible_end_date: false,
      recovery_pattern: :every_other,
      vertical_build_percentage: 10,
      status: :planned
    )
  end

  test "valid plan" do
    assert @plan.valid?
  end

  test "invalid without user" do
    @plan.user = nil
    assert_not @plan.valid?
  end

  test "invalid if goal_vertical_distance <= baseline_vertical_distance" do
    @plan.goal_vertical_distance = 500
    assert_not @plan.valid?
  end

  test "vertical_build_percentage must be within range" do
    @plan.vertical_build_percentage = 20
    assert_not @plan.valid?
    @plan.vertical_build_percentage = 4
    assert_not @plan.valid?
    @plan.vertical_build_percentage = 10
    assert @plan.valid?
  end

  test "end_date must be after start_date if present" do
    @plan.end_date = @plan.start_date - 1
    assert_not @plan.valid?
  end

  test "plan status transitions" do
    @plan.status = :active
    assert @plan.active?
    @plan.completed!
    assert @plan.valid?
    assert @plan.completed?
    @plan.abandoned!
    assert @plan.abandoned?
    assert @plan.valid?
  end

  test "enums work" do
    assert_equal "every_other", @plan.recovery_pattern
    assert_equal "planned", @plan.status
  end
end
