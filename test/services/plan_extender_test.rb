require "test_helper"

class PlanExtenderTest < ActiveSupport::TestCase
  def setup
    @plan = plans(:user_two_active)
    @target_end_date = @plan.end_date + 10.weeks
  end

  test "extends the plan and persists generated weeks and days" do
    original_week_count = @plan.weeks.count

    result = PlanExtender.new(@plan, @target_end_date).call

    assert result.success?
    assert_equal @plan, result.plan
    assert_operator @plan.reload.end_date, :>=, @target_end_date
    assert_operator @plan.weeks.count, :>, original_week_count
    assert_equal @plan.weeks.maximum(:week_number), @plan.weeks.count
    assert @plan.weeks.all? { |week| week.days.exists? }
  end

  test "removes the previous taper and goal weeks when extending" do
    taper = Week.create!(plan: @plan, week_number: 12, status: :planned,
      planned_duration: 200, planned_vertical_distance: 1000,
      category: :taper, recovery_reduction_percentage: 40,
      start_date: @plan.end_date + 1.day, end_date: @plan.end_date + 7.days)
    goal = Week.create!(plan: @plan, week_number: 13, status: :planned,
      planned_vertical_distance: 4300, category: :goal,
      recovery_reduction_percentage: 60,
      start_date: @plan.end_date + 8.days, end_date: @plan.end_date + 14.days)

    result = PlanExtender.new(@plan, @target_end_date).call

    assert result.success?
    refute Week.exists?(taper.id)
    refute Week.exists?(goal.id)
  end

  test "rejects a plan without dates" do
    plan = plans(:user_one_planned)

    error = assert_raises(ArgumentError) do
      PlanExtender.new(plan, Date.today + 1.month).call
    end

    assert_equal "plan has no dates to extend from", error.message
  end

  test "rejects a target end date that is not after the current end date" do
    error = assert_raises(ArgumentError) do
      PlanExtender.new(@plan, @plan.end_date).call
    end

    assert_equal "target_end_date must be after the plan's current end_date", error.message
  end

  test "returns an unsuccessful result and rolls back when day generation fails" do
    generated_week = Week.new(
      plan: @plan,
      week_number: @plan.weeks.maximum(:week_number) + 1,
      planned_duration: 200,
      planned_vertical_distance: 2000,
      category: :progression,
      status: :planned,
      vertical_build_percentage: 10,
      start_date: @plan.end_date + 1.day,
      end_date: @plan.end_date + 7.days
    )
    week_generator = mock("week_generator")
    week_generator.expects(:build_weeks).returns([ generated_week ])
    WeekGenerator.stubs(:new).returns(week_generator)

    day_generator = mock("day_generator")
    day_generator.expects(:build_days).raises(ArgumentError, "invalid day distribution")
    DayGenerator.stubs(:new).returns(day_generator)

    result = PlanExtender.new(@plan, @target_end_date).call

    refute result.success?
    assert_includes result.plan.errors.full_messages, "Day generation failed: invalid day distribution"
    refute Week.exists?(generated_week.id)
    assert_equal @plan.end_date, @plan.reload.end_date
  end

  test "returns an unsuccessful result when week generation produces no weeks" do
    week_generator = mock("week_generator")
    week_generator.expects(:build_weeks).returns([])
    WeekGenerator.stubs(:new).returns(week_generator)

    original_end_date = @plan.end_date
    original_week_count = @plan.weeks.count

    result = PlanExtender.new(@plan, @target_end_date).call

    refute result.success?
    assert_equal original_end_date, @plan.reload.end_date
    assert_equal original_week_count, @plan.weeks.count
  end
end
