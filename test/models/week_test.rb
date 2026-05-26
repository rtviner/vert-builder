require "test_helper"

class WeekTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @plan = Plan.create!(user: @user, baseline_vertical_distance: 100, baseline_duration: 60, goal_vertical_distance: 200, recovery_pattern: 0, vertical_build_percentage: 10, status: 0)
    @week = Week.new(child: @plan, week_number: 1, is_recovery: false, status: 0, start_date: Date.today, end_date: Date.today + 6, planned_duration: 60, completed_duration: 0, planned_vertical_distance: 100, completed_vertical_distance: 0)
  end

  test "invalid without required fields" do
    @week.week_number = nil
    assert_not @week.valid?
    assert_includes @week.errors[:week_number], "can't be blank"
  end

  test "week_number must be unique per plan" do
    @week.save!
    dup = @week.dup
    assert_not dup.valid?
    assert_includes dup.errors[:week_number], "has already been taken"
  end

  test "complete! sets status to completed" do
    @week.save!
    @week.complete!
    assert_equal "completed", @week.status
  end

  test "log_week_progress updates values and completes if needed" do
    @week.save!
    @week.end_date = Date.yesterday
    @week.log_week_progress(vertical_distance: 120, duration: 70)
    assert_equal 120, @week.completed_vertical_distance
    assert_equal 70, @week.completed_duration
    assert_equal "completed", @week.status
  end
end
