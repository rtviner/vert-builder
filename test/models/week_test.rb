require "test_helper"
class WeekTest < ActiveSupport::TestCase
  setup do
    @plan = plans(:one)
    @week = Week.new(
      plan: @plan,
      week_number: 2,
      is_recovery: false,
      status: :upcoming,
      start_date: Date.today,
      end_date: Date.today + 6,
      planned_duration: 10,
      completed_duration: 0,
      planned_vertical_distance: 3000,
      completed_vertical_distance: 0
    )
  end

  test "valid week" do
    assert @week.valid?
  end

  test "invalid without required fields" do
    @week.start_date = nil
    assert_not @week.valid?
    assert_includes @week.errors[:start_date], "can't be blank"
  end

  test "week_number must be > 0" do
    @week.week_number = 0
    assert_not @week.valid?
    assert_includes @week.errors[:week_number], "must be greater than 0"
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
      is_recovery: false,
      status: :completed,
      start_date: Date.today,
      end_date: Date.today + 6,
      planned_duration: 10,
      completed_duration: 10,
      planned_vertical_distance: 100,
      completed_vertical_distance: 100
    )
    assert_includes Week.completed_weeks, completed
  end
end
