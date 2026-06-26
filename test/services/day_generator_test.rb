require "test_helper"

class DayGeneratorTest < ActiveSupport::TestCase
  def setup
    @generator = DayGenerator.new
  end

  def assert_randomized_days(total:, count:, max:, expected_count:)
    days = @generator.send(:randomize_days_with_sum, total: total, count: count, max: max)

    assert_equal expected_count, days.count
    assert_in_delta total, days.sum, 10, "expected sum of days to be within 10 of #{total}, got #{days.sum}"
    assert days.all? { |day| day <= max }, "expected each day to be <= #{max}, got #{days.inspect}"
    assert days.all? { |day| day >= 0 }, "expected non-negative days, got #{days.inspect}"
    assert days.all? { |day| (day % 10).zero? }, "expected multiples of 10, got #{days.inspect}"

    days
  end

  test "progression distributes four easy days for low, mid, and high week vert" do
    scenarios = [
      { week_vert: 1_500.0, total_hard_percentage: 0.75, label: "low" },
      { week_vert: 6_000.0, total_hard_percentage: 0.78, label: "mid" },
      { week_vert: 15_000.0, total_hard_percentage: 0.80, label: "high" }
    ]

    scenarios.each do |scenario|
      easy_days_total = scenario[:week_vert] * (1 - scenario[:total_hard_percentage])
      max_easy = scenario[:week_vert] * DayGenerator::MAX_EASY_PERCENTAGE

      days = assert_randomized_days(total: easy_days_total, count: 4, max: max_easy, expected_count: 4)
      assert days.none?(&:zero?), "expected no zero easy days for #{scenario[:label]} week_vert"
      assert days.select { |day| day == 90 }.count <= 3,
             "expected 3 or fewer 90 values for #{scenario[:label]} week_vert"
      assert days.select { |day| day > 90 && day < 150 }.count <= 1,
             "expected 1 or fewer 90-150 values for #{scenario[:label]} week_vert"
    end
  end

  test "build recovery distribution spreads five days for low, mid, and high week vert" do
    scenarios = [
      { week_vert: 990.0, label: "low" },
      { week_vert: 4_500.0, label: "mid" },
      { week_vert: 9_000.0, label: "high" }
    ]

    scenarios.each do |scenario|
      remaining_5_days_total = scenario[:week_vert] * 0.40
      max_easy = scenario[:week_vert] * DayGenerator::MAX_EASY_PERCENTAGE

      days = assert_randomized_days(total: remaining_5_days_total, count: 5, max: max_easy, expected_count: 5)
      assert days.select { |day| day == 0 }.count <= 1,
             "expected at most one zero day for #{scenario[:label]} week_vert"
      assert days.select { |day| day == 90 }.count <= 3,
             "expected 3 or fewer 90 values for #{scenario[:label]} week_vert"
      assert days.select { |day| day > 90 && day < 150 }.count <= 1,
             "expected 1 or fewer 90-150 values for #{scenario[:label]} week_vert"
    end
  end

  test "build goal normal remaining distributes three days for low, mid, and high recovery vert" do
    scenarios = [
      { recovery_vert: 1_500.0, remainder: 600.0, label: "low" },
      { recovery_vert: 3_600.0, remainder: 1_400.0, label: "mid" },
      { recovery_vert: 6_900.0, remainder: 2_760.0, label: "high" }
    ]

    scenarios.each do |scenario|
      max_easy = scenario[:recovery_vert] * DayGenerator::MAX_EASY_PERCENTAGE
      days = assert_randomized_days(total: scenario[:remainder], count: 3, max: max_easy, expected_count: 3)

      assert days.select { |day| day == 90 }.count <= 1,
             "expected at most one 90-day value for #{scenario[:label]} recovery_vert"
      assert days.select { |day| day > 90 && day < 150 }.count <= 1,
             "expected 1 or fewer 90-150 values for #{scenario[:label]} recovery_vert"
      assert days.all? { |day| day > 0 },
             "expected all days to be positive for #{scenario[:label]} recovery_vert"
    end
  end
end
