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

  # these tests depend on week generation, which is not implemented yet — to be added in Prompt 3

  # test "sets plan end_date after saving when flexible_end_date is true" do
  #   @plan.flexible_end_date = true
  #   result = @generator.call
  #   assert result.plan.end_date.present?
  # end

  # test "does not set plan end_date when flexible_end_date is false" do
  #   @plan.flexible_end_date = false
  #   @plan.end_date = Date.today + 90.days
  #   result = @generator.call

  #   assert_equal Date.today + 90.days, result.plan.end_date
  # end

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
