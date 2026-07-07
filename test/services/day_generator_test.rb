require "test_helper"

class DayGeneratorTest < ActiveSupport::TestCase
  def setup
    @generator = DayGenerator.new
  end

  def assert_randomized_days(total:, count:, max:, expected_count:)
    days = @generator.send(:randomize_days_with_sum, total: total, count: count, max: max)

    assert_equal expected_count, days.count
    assert_in_delta total, days.sum, count * 10, "expected sum of days to be within #{count * 10} of #{total}, got #{days.sum}"
    assert days.all? { |day| day <= max }, "expected each day to be <= #{max}, got #{days.inspect}"
    assert days.all? { |day| (day % 10).zero? }, "expected multiples of 10, got #{days.inspect}"

    days
  end

  test "randomize_days_with_sum distributes four easy days for low, mid, and high progression week vert" do
    scenarios = [
      { week_vert: 1_000.0, total_hard_percentage: 0.75, label: "low" },
      { week_vert: 6_020.0, total_hard_percentage: 0.78, label: "mid" },
      { week_vert: 15_010.0, total_hard_percentage: 0.80, label: "high" }
    ]

    scenarios.each do |scenario|
      easy_days_total = scenario[:week_vert] * (1 - scenario[:total_hard_percentage])
      max_easy = scenario[:week_vert] * DayGenerator::MAX_EASY_PERCENTAGE

      days = assert_randomized_days(total: easy_days_total, count: 4, max: max_easy, expected_count: 4)
      assert days.select { |day| day == 90 }.count <= 3,
             "expected 3 or fewer 90 values for #{scenario[:label]} week_vert"
      assert days.select { |day| day > 90 && day < 150 }.count <= 1,
             "expected 1 or fewer 90-150 values for #{scenario[:label]} week_vert"
    end
  end

  test "randomize_days_with_sum distributes five days for low, mid, and high recovery week vert" do
    scenarios = [
      { week_vert: 660.0, label: "low" },
      { week_vert: 4_500.0, label: "mid" },
      { week_vert: 9_000.0, label: "high" }
    ]

    scenarios.each do |scenario|
      long_day = (scenario[:week_vert] * 0.40).round(-1)
      medium_day = (scenario[:week_vert] * 0.20).round(-1)

      easy_5_days_total = scenario[:week_vert] - long_day - medium_day
      max_easy = scenario[:week_vert] * DayGenerator::MAX_EASY_PERCENTAGE

      days = assert_randomized_days(total: easy_5_days_total, count: 5, max: max_easy, expected_count: 5)
      assert days.select { |day| day > 90 && day < 150 }.count <= 1,
             "expected 1 or fewer 90-150 values for #{scenario[:label]} week_vert"
    end
  end

  test "randomize_days_with_sum distributes four days for low, mid, and high goal week recovery vert" do
    scenarios = [
      { recovery_vert: 1_500.0, remainder: 600.0, label: "low" },
      { recovery_vert: 3_600.0, remainder: 1_400.0, label: "mid" },
      { recovery_vert: 6_900.0, remainder: 2_760.0, label: "high" }
    ]

    scenarios.each do |scenario|
      max_easy = scenario[:recovery_vert] * DayGenerator::MAX_EASY_PERCENTAGE
      days = assert_randomized_days(total: scenario[:remainder], count: 4, max: max_easy, expected_count: 4)

      assert days.select { |day| day == 90 }.count <= 1,
             "expected at most one 90-day value for #{scenario[:label]} recovery_vert"
      assert days.select { |day| day > 90 && day < 150 }.count <= 1,
             "expected 1 or fewer 90-150 values for #{scenario[:label]} recovery_vert"
      assert days.all? { |day| day > 0 },
             "expected all days to be positive for #{scenario[:label]} recovery_vert"
    end
  end
  test "build_days raises for unknown week type" do
    week = Week.new(planned_vertical_distance: 1000, category: "unknown")

    assert_raises(ArgumentError) do
      @generator.build_days(week, goal_vertical_distance = 3200)
    end
  end

  test "build_days generates seven days with expected ordering for low, mid, and high progression week totals" do
    scenarios = [
      { week_vert: 1000, label: "low" },
      { week_vert: 6_020, label: "mid" },
      { week_vert: 15_010, label: "high" }
    ]

    scenarios.each do |scenario|
      week = Week.new(planned_vertical_distance: scenario[:week_vert], category: "progression")
      days = @generator.build_days(week, goal_vertical_distance = 3200)

      assert_equal 7, days.count
      assert days.all? { |day| day.status == "upcoming" }
      assert_in_delta days.sum(&:planned_vertical_distance), week.planned_vertical_distance, 70

      easy_positions = [ 0, 2, 4, 6 ]
      hard_and_long_positions = [ 1, 3, 5 ]

      max_easy = week.planned_vertical_distance * 0.15
      easy_positions.each do |index|
        assert_operator days[index].planned_vertical_distance, :>=, 0
        assert_operator days[index].planned_vertical_distance, :<=, max_easy
      end

      long_day = days[3].planned_vertical_distance
      assert_in_delta (week.planned_vertical_distance * 0.35).round, long_day, 20

      hard_sum = hard_and_long_positions.sum { |index| days[index].planned_vertical_distance }

      assert_operator hard_sum, :>=, week.planned_vertical_distance * 0.75
      assert_operator hard_sum, :<=, week.planned_vertical_distance * 0.80

      assert days.all? { |day| (day.planned_vertical_distance % 10).zero? }
    end
  end

  test "build_days generates seven days with expected ordering for low, mid, and high recovery week totals" do
    scenarios = [
      { week_vert: 660.0, label: "low" },
      { week_vert: 4_520.0, label: "mid" },
      { week_vert: 9_010.0, label: "high" }
    ]

    scenarios.each do |scenario|
      week = Week.new(planned_vertical_distance: scenario[:week_vert], category: "recovery")
      days = @generator.build_days(week, goal_vertical_distance = 3200)

      assert_equal 7, days.count
      assert days.all? { |day| day.status == "upcoming" }
      assert_in_delta days.sum(&:planned_vertical_distance), week.planned_vertical_distance, 70

      easy_positions = [ 0, 1, 3, 4, 6 ]

      max_easy = week.planned_vertical_distance * 0.15
      easy_positions.each do |index|
        assert_operator days[index].planned_vertical_distance, :>=, 0
        assert_operator days[index].planned_vertical_distance, :<=, max_easy
      end

      long_day = days[2].planned_vertical_distance
      assert_in_delta (week.planned_vertical_distance * 0.40).round, long_day, 10
      medium_day = days[5].planned_vertical_distance
      assert_in_delta (week.planned_vertical_distance * 0.20), medium_day, 10

      assert days.all? { |day| (day.planned_vertical_distance % 10).zero? }
    end
  end

  test "build_days generates seven days with expected ordering for low, mid, and high taper week totals" do
    scenarios = [
      { week_vert: 1_330, label: "low" },
      { week_vert: 4_510, label: "mid" },
      { week_vert: 9_020, label: "high" }
    ]

    scenarios.each do |scenario|
      week = Week.new(planned_vertical_distance: scenario[:week_vert], category: "taper")
      days = @generator.build_days(week, goal_vertical_distance = 3200)

      assert_equal 7, days.count
      assert days.all? { |day| day.status == "upcoming" }
      assert_in_delta days.sum(&:planned_vertical_distance), week.planned_vertical_distance, 70

      easy_positions = [ 1, 3, 4, 5, 6 ]

      max_easy = week.planned_vertical_distance * 0.15
      easy_positions.each do |index|
        assert_operator days[index].planned_vertical_distance, :>=, 0
        assert_operator days[index].planned_vertical_distance, :<=, max_easy
      end

      long_day = days[0].planned_vertical_distance
      assert_in_delta (week.planned_vertical_distance * 0.40).round, long_day, 10
      medium_day = days[2].planned_vertical_distance
      assert_in_delta (week.planned_vertical_distance * 0.20), medium_day, 10

      assert days.all? { |day| (day.planned_vertical_distance % 10).zero? }
    end
  end

  test "build_days generates seven days with expected ordering for low, mid, and high goal week totals" do
    scenarios = [
      { week_vert: 2_880, goal_vertical_distance: 2000, label: "low" },
      { week_vert: 7_220, goal_vertical_distance: 6000, label: "mid" },
      { week_vert: 20_010, goal_vertical_distance: 12000, label: "high" }
    ]

    scenarios.each do |scenario|
      week = Week.new(planned_vertical_distance: scenario[:week_vert], category: "goal")
      goal_vertical_distance = scenario[:goal_vertical_distance]
      days = @generator.build_days(week, goal_vertical_distance)

      assert_equal 7, days.count
      assert days.all? { |day| day.status == "upcoming" }
      assert_in_delta days.sum(&:planned_vertical_distance), week.planned_vertical_distance, 70

      easy_positions = [ 1, 3, 4, 6 ]

      max_easy = week.planned_vertical_distance * 0.15
      easy_positions.each do |index|
        assert_operator days[index].planned_vertical_distance, :>=, 0
        assert_operator days[index].planned_vertical_distance, :<=, max_easy
      end

      long_day = days[0].planned_vertical_distance
      recovery_vertical_distance = week.planned_vertical_distance - goal_vertical_distance
      assert_in_delta (recovery_vertical_distance * 0.40), long_day, 10
      medium_day = days[2].planned_vertical_distance
      assert_in_delta (recovery_vertical_distance * 0.20), medium_day, 10

      assert days.all? { |day| (day.planned_vertical_distance % 10).zero? }
    end
  end
end
