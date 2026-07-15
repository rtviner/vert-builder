require "test_helper"

class PlanGeneratorTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @plan = Plan.new(
      user: @user,
      baseline_vertical_distance: 1624,
      baseline_duration: 180,
      goal_vertical_distance: 3300,
      start_date: Date.today,
      flexible_end_date: true,
      recovery_pattern: :every_other,
      vertical_build_percentage: 10,
      status: :planned
    )
    @generator = PlanGenerator.new(@plan)
  end

  def build_week(week_number:, end_date:)
    Week.new(
      plan: @plan,
      week_number: week_number,
      planned_vertical_distance: 2000,
      planned_duration: 100,
      category: "progression",
      status: :planned,
      recovery_reduction_percentage: nil,
      vertical_build_percentage: 10,
      end_date: end_date
    )
  end

  def build_day(week)
    Day.new(
      week: week,
      planned_vertical_distance: 100,
      status: :upcoming
    )
  end

  test "returns a PlanResult" do
    result = @generator.call
    assert_instance_of PlanGenerator::PlanResult, result
  end

  test "returns success? true when plan saves successfully" do
    result = @generator.call
    assert result.success?
  end

  test "returns the plan on the result" do
    result = @generator.call
    assert_equal @plan, result.plan
  end

  test "saves the plan record" do
    assert_difference "Plan.count", 1 do
      @generator.call
    end
  end

  test "does not save the plan if it is invalid" do
    assert_no_difference [ "Plan.count", "Week.count", "Day.count" ] do
      @plan.goal_vertical_distance = nil
      @generator.call
    end
  end

  test "adds specific errors to the plan on failure" do
    @plan.baseline_vertical_distance = nil
    result = @generator.call

    assert result.plan.errors[:baseline_vertical_distance].present?
  end

  test "delegates week and day generation and persists the generated records" do
    week_one = build_week(week_number: 1, end_date: Date.today + 6.days)
    week_two = build_week(week_number: 2, end_date: Date.today + 13.days)
    day_one = build_day(week_one)
    day_two = build_day(week_one)
    day_three = build_day(week_two)

    week_generator = mock("week_generator")
    week_generator.expects(:build_weeks).returns([ week_one, week_two ])
    WeekGenerator.stubs(:new).with(@plan).returns(week_generator)

    day_generator = mock("day_generator")
    day_generator.expects(:build_days).with(week_one, @plan.goal_vertical_distance).returns([ day_one, day_two ])
    day_generator.expects(:build_days).with(week_two, @plan.goal_vertical_distance).returns([ day_three ])
    DayGenerator.stubs(:new).returns(day_generator)

    result = @generator.call

    assert result.success?
    assert_equal [ week_one, week_two ], @plan.weeks.to_a
    assert_equal [ day_one, day_two, day_three ], @plan.weeks.flat_map(&:days).sort_by(&:id)
  end

  test "rolls back all records if plan save fails" do
    assert_no_difference [ "Plan.count", "Week.count", "Day.count" ] do
      Plan.any_instance.stubs(:save!).raises(ActiveRecord::RecordInvalid.new(@plan))
      @generator.call
    end
    assert_not @plan.persisted?
  end

  test "returns success? false when plan is invalid" do
    @plan.baseline_vertical_distance = nil
    result = @generator.call

    assert_not result.success?
  end
end
