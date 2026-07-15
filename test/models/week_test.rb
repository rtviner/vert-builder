require "test_helper"
class WeekTest < ActiveSupport::TestCase
  setup do
    @plan = plans(:one)
    @week = Week.new(
      plan: @plan,
      week_number: 2,
      status: :upcoming,
      start_date: Date.today,
      end_date: Date.today + 6,
      planned_duration: 10,
      completed_duration: 0,
      planned_vertical_distance: 3000,
      completed_vertical_distance: 0,
      category: "progression",
      vertical_build_percentage: 10
    )
  end

  test "valid week" do
    assert @week.valid?
  end

  test "invalid without required fields" do
    @week.planned_vertical_distance = nil
    assert_not @week.valid?
    assert_includes @week.errors[:planned_vertical_distance], "can't be blank"
  end

  test "start date and end date are not required if the week is planned" do
    @week.status = :planned
    @week.start_date = nil
    @week.end_date = nil
    assert @week.valid?
  end

  test "week_number must be > 0" do
    @week.week_number = 0
    @week.category = nil
    assert_not @week.valid?
    assert_includes @week.errors[:week_number], "must be greater than 0"
    assert_includes @week.errors[:category], "can't be blank"
  end

  test "week_number must be unique within the same plan" do
    duplicate_week = @week.dup
    duplicate_week.week_number = 1
    duplicate_week.save
    assert_not duplicate_week.valid?
    assert_includes duplicate_week.errors[:week_number], "has already been taken"
  end

  test "end_date must be after start_date" do
    @week.start_date = Date.today
    @week.end_date = Date.yesterday
    assert_not @week.valid?
    assert_includes @week.errors[:end_date], "must be after the start date"
  end

  test "status can be transitioned to completed only with completed fields" do
    @week.completed_duration = nil
    @week.completed_vertical_distance = nil
    @week.status = :completed
    assert_not @week.valid?
    assert_includes @week.errors[:completed_vertical_distance], "can't be blank"
    assert_includes @week.errors[:completed_duration], "can't be blank"
  end

  test "completed_weeks scope" do
    completed = Week.create!(
      plan: @plan,
      week_number: 2,
      status: :completed,
      start_date: Date.today,
      end_date: Date.today + 6,
      planned_duration: 10,
      completed_duration: 10,
      planned_vertical_distance: 100,
      completed_vertical_distance: 100,
      category: "progression",
      vertical_build_percentage: 10
    )
    assert_includes Week.completed, completed
  end

  test "check_completion! marks week as completed if end_date has passed and all days are completed or skipped" do
    @week.save!
    @week.days.create!(planned_vertical_distance: 1000, completed_vertical_distance: 1000, status: :completed)
    @week.days.create!(planned_vertical_distance: 2000, completed_vertical_distance: 2000, status: :completed)
    travel_to @week.end_date + 1 do
      @week.check_completion!
      assert @week.completed?
    end
  end

  test "check_completion! skips upcoming days if end_date has passed" do
    @week.save!
    day1 = @week.days.create!(planned_vertical_distance: 1000, completed_vertical_distance: 0, status: :upcoming)
    day2 = @week.days.create!(planned_vertical_distance: 2000, completed_vertical_distance: 0, status: :upcoming)
    travel_to @week.end_date + 1 do
      @week.check_completion!
      assert day1.reload.skipped?
      assert day2.reload.skipped?
      assert @week.completed?
    end
  end
end
