require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "average_weekly_vertical_distance returns baseline if less than 4 completed weeks" do
    user = users(:one)
    assert_equal plans(:one).baseline_vertical_distance, user.average_weekly_vertical_distance
  end

  test "average_weekly_vertical_distance returns average of last 4 completed weeks" do
    user = users(:one)
    plan = plans(:one)
    weeks(:one).update(status: :completed, completed_vertical_distance: 1000)
    first_week = weeks(:one)
    4.times do |i|
      start_date = first_week.start_date + ((i + 1) * 7)
      plan.weeks.create!(
        week_number: i + 2,
        start_date: start_date,
        end_date: start_date + 6,
        status: :completed,
        completed_vertical_distance: 1000 + i * 100,
        category: "progression",
        vertical_build_percentage: 10,
        recovery_reduction_percentage: nil,
        planned_duration: 100 + i * 10,
      )
    end
    last_four_weeks = plan.weeks.order(end_date: :desc).limit(4)
    expected_average = last_four_weeks.reduce(0) { |sum, week| sum + week.completed_vertical_distance } / 4
    assert_equal expected_average, user.average_weekly_vertical_distance
  end

  test "average_weekly_duration returns baseline if less than 4 completed weeks" do
    user = users(:one)
    assert_equal plans(:one).baseline_duration, user.average_weekly_duration
  end

  test "average_weekly_duration returns average of last 4 completed weeks" do
    user = users(:one)
    plan = plans(:one)
    weeks(:one).update(status: :completed, completed_duration: 120)
    first_week = weeks(:one)
    4.times do |i|
      start_date = first_week.start_date + ((i + 1) * 7)
      plan.weeks.create!(
        week_number: i + 2,
        start_date: start_date,
        end_date: start_date + 6,
        status: :completed,
        completed_duration: 120 + i * 10,
        category: "progression",
        planned_duration: 120 + i * 10,
        vertical_build_percentage: 10,
        recovery_reduction_percentage: nil,
      )
    end
    last_four_weeks = plan.weeks.order(end_date: :desc).limit(4)
    expected_average = last_four_weeks.reduce(0) { |sum, week| sum + week.completed_duration } / 4
    assert_equal expected_average, user.average_weekly_duration
  end
end
