require "test_helper"

class WeekGeneratorTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
  end

  def build_plan(overrides = {})
    Plan.new({
      user: @user,
      baseline_vertical_distance: 1624,
      baseline_duration: 180,
      goal_vertical_distance: 3300,
      flexible_end_date: true,
      recovery_pattern: :every_other,
      vertical_build_percentage: 10,
      status: :planned
    }.merge(overrides))
  end

  def generator(plan)
    WeekGenerator.new(plan)
  end

  test "fails if baseline vertical distance is below minimum" do
    plan = build_plan(baseline_vertical_distance: 500)
    result = generator(plan).build_weeks

    assert_empty result
    assert plan.errors[:baseline_vertical_distance].include?("must be greater than or equal to #{Plan::MINIMUM_BASELINE_VERT}")
  end

  test "generates a minimum of 5 weeks" do
    weeks = generator(build_plan).build_weeks

    assert_operator weeks.count, :>=, 5
  end

  test "second to last week is taper and last week is goal" do
    weeks = generator(build_plan).build_weeks
    ordered_weeks = weeks.sort_by(&:week_number)

    assert_equal "taper", ordered_weeks.second_to_last.category
    assert_equal "goal", ordered_weeks.last.category
  end

  test "progression weeks calculate vertical distance and duration from the previous progression week and the vertical build percentage" do
    plan = build_plan(vertical_build_percentage: 10)
    weeks = generator(plan).build_weeks
    progression_weeks = weeks.select { |week| week.category == "progression" }

    progression_weeks.each_cons(2) do |previous_week, current_week|
      expected_vertical_distance = (previous_week.planned_vertical_distance * (1 + plan.vertical_build_percentage / 100.0)).round(-1)
      assert_equal expected_vertical_distance, current_week.planned_vertical_distance
      expected_duration = (previous_week.planned_duration * (1 + (Plan::MAX_PROGRESSION_PERCENTAGE - plan.vertical_build_percentage) / 100.0)).round
      assert_equal expected_duration, current_week.planned_duration
    end
  end


  test "recovery weeks calculate vertical distance and duration from the previous progression week and recovery reduction percentage" do
    plan = build_plan
    weeks = generator(plan).build_weeks

    weeks.each_with_index do |week, index|
      next unless week.category == "recovery"

      previous_progression = weeks[0..index - 1].reverse.find { |candidate| candidate.category == "progression" }
      expected = (previous_progression.planned_vertical_distance * (1 - WeekGenerator::RECOVERY_REDUCTION_PERCENTAGE / 100.0)).round(-1)
      assert_equal expected, week.planned_vertical_distance

      expected_duration = (previous_progression.planned_duration * (1 - WeekGenerator::RECOVERY_REDUCTION_PERCENTAGE / 100.0)).round
      assert_equal expected_duration, week.planned_duration
    end
  end

  test "recovery weeks are generated according to the recovery pattern" do
    plan = build_plan(recovery_pattern: :every_other)
    weeks = generator(plan).build_weeks
    weeks.each_with_index do |week, index|
      if week.category == "taper" || week.category == "goal"
        next
      end
      if index.odd?
        assert_equal "recovery", week.category
      else
        assert_equal "progression", week.category
      end
    end
    plan = build_plan(recovery_pattern: :every_third)
    weeks = generator(plan).build_weeks
    weeks.each_with_index do |week, index|
      if week.category == "taper" || week.category == "goal"
        next
      end
      if index % 3 == 2
        assert_equal "recovery", week.category
      else
        assert_equal "progression", week.category
      end
    end
    plan = build_plan(recovery_pattern: :every_fourth)
    weeks = generator(plan).build_weeks
    weeks.each_with_index do |week, index|
      if week.category == "taper" || week.category == "goal"
        next
      end
      if index % 4 == 3
        assert_equal "recovery", week.category
      else
        assert_equal "progression", week.category
      end
    end
  end

  test "taper week calculates vertical distance and duration from the final progression week and recovery reduction percentage" do
    plan = build_plan
    weeks = generator(plan).build_weeks
    taper_week = weeks.find { |week| week.category == "taper" }
    final_progression_week = weeks.reverse.find { |week| week.category == "progression" }
    taper_week_expected_vertical_distance = (final_progression_week.planned_vertical_distance * (1 - WeekGenerator::RECOVERY_REDUCTION_PERCENTAGE / 100.0)).round(-1)
    assert_equal taper_week_expected_vertical_distance, taper_week.planned_vertical_distance
    taper_week_expected_duration = (final_progression_week.planned_duration * (1 - WeekGenerator::RECOVERY_REDUCTION_PERCENTAGE / 100.0)).round
    assert_equal taper_week_expected_duration, taper_week.planned_duration
  end

  test "goal week calculates vertical distance from the final progression week and goal vertical distance and has no planned duration" do
    plan = build_plan
    weeks = generator(plan).build_weeks
    goal_week = weeks.find { |week| week.category == "goal" }
    final_progression_week = weeks.reverse.find { |week| week.category == "progression" }
    goal_week_expected_vertical_distance = (final_progression_week.planned_vertical_distance * (1 - WeekGenerator::GOAL_WEEK_REDUCTION_PERCENTAGE / 100.0)).round(-1) + plan.goal_vertical_distance
    assert_equal goal_week_expected_vertical_distance, goal_week.planned_vertical_distance
    assert_nil goal_week.planned_duration
  end

  test "weeks have planned status and no start or end dates during generation" do
    weeks = generator(build_plan).build_weeks

    weeks.each do |week|
      assert_equal "planned", week.status
      assert_nil week.start_date
      assert_nil week.end_date
    end
  end
end
