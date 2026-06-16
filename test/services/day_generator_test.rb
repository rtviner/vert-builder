require "test_helper"

class DayGeneratorTest < ActiveSupport::TestCase
  def setup
    @generator = DayGenerator.new()
  end

  test "build_days raises for unknown week type" do
    week = Week.new(planned_vertical_distance: 1000, category: "unknown")

    assert_raises(ArgumentError) do
      @generator.build_days(week, goal_vertical_distance = 3200)
    end
  end

  test "progression week generates seven days with expected ordering" do
    week = Week.new(planned_vertical_distance: 3000, category: "progression")
    days = @generator.build_days(week, goal_vertical_distance = 3200)

    assert_equal 7, days.count
    assert days.all? { |day| day.status == "upcoming" }
    assert_equal 3000, days.sum(&:planned_vertical_distance)

    easy_positions = [ 0, 2, 4, 6 ]
    hard_positions = [ 1, 5 ]

    max_easy = (week.planned_vertical_distance * 0.15).to_i
    easy_positions.each do |index|
      assert_operator days[index].planned_vertical_distance, :>=, 90
      assert_operator days[index].planned_vertical_distance, :<=, max_easy
    end

    long_day = days[3].planned_vertical_distance
    assert_in_delta 1050, long_day, 20

    hard_sum = hard_positions.sum { |index| days[index].planned_vertical_distance }
    assert_in_delta (week.planned_vertical_distance * 0.775).round, hard_sum, 20

    assert days.all? { |day| (day.planned_vertical_distance % 10).zero? }
  end

  test "progression fallback uses one zero easy day and three equal easy days" do
    week = Week.new(planned_vertical_distance: 1400, category: "progression")
    days = @generator.build_days(week, goal_vertical_distance = 3200)

    easy_values = [ days[0].planned_vertical_distance, days[2].planned_vertical_distance,
                   days[4].planned_vertical_distance, days[6].planned_vertical_distance ]
    assert_equal 1, easy_values.count(0)

    non_zero_values = easy_values.reject(&:zero?)
    assert_equal 3, non_zero_values.count
    assert_equal non_zero_values.uniq.size, 1
  end

  test "build_recovery_distribution returns expected keys and totals" do
    week = Week.new(planned_vertical_distance: 3000, category: "recovery")
    distribution = @generator.build_recovery_distribution(week)

    assert distribution.key?(:long_day)
    assert distribution.key?(:medium_day)
    assert distribution.key?(:remaining_5)
    assert_equal 5, distribution[:remaining_5].count

    assert_in_delta 1200, distribution[:long_day], 20
    assert_in_delta 600, distribution[:medium_day], 20
    assert_in_delta 1200, distribution[:remaining_5].sum, 20
    assert_equal 1, distribution[:remaining_5].count { |value| value.between?(90, 100) }
    assert distribution[:remaining_5].all? { |value| value <= week.planned_vertical_distance * 0.15 }
  end

  test "build_recovery_distribution fallback contains exactly one zero remaining day" do
    week = Week.new(planned_vertical_distance: 1000, category: "recovery")
    distribution = @generator.build_recovery_distribution(week)

    assert_equal 1, distribution[:remaining_5].count(0)
    assert_in_delta 1000, distribution[:long_day] + distribution[:medium_day] + distribution[:remaining_5].sum, 20
  end

  test "build_recovery_days never places long and medium days adjacent" do
    week = Week.new(planned_vertical_distance: 3000, category: "recovery")

    10.times do
      days = @generator.build_recovery_days(week)
      sorted = days.each_with_index.sort_by { |day, _| day.planned_vertical_distance }
      long_index = sorted.last.last
      medium_index = sorted[-2].last

      assert_operator (long_index - medium_index).abs, :>, 1
    end
  end

  test "taper week orders long, remaining, medium correctly" do
    week = Week.new(planned_vertical_distance: 3000, category: "taper")
    days = @generator.build_days(week, goal_vertical_distance = 3200)

    assert_equal 7, days.count
    assert_operator days[0].planned_vertical_distance, :>, days[2].planned_vertical_distance
    assert_operator days[1].planned_vertical_distance, :<, days[0].planned_vertical_distance
    assert_in_delta 600, days[2].planned_vertical_distance, 20
    assert_equal 3000, days.sum(&:planned_vertical_distance)
  end

  test "goal week places goal day on day six and derives long/medium from recovery distance" do
    week = Week.new(planned_vertical_distance: 3000, category: "goal")
    days = @generator.build_days(week, goal_vertical_distance = 3200)

    assert_equal 7, days.count
    assert_equal 1200, days[5].planned_vertical_distance
    assert_in_delta 720, days[0].planned_vertical_distance, 20
    assert_in_delta 360, days[2].planned_vertical_distance, 20
    assert_equal 3000, days.sum(&:planned_vertical_distance)
  end

  test "goal week fallback generates exactly one zero remaining day" do
    week = Week.new(planned_vertical_distance: 1300, category: "goal")
    days = @generator.build_days(week, goal_vertical_distance = 3200)

    remaining_positions = [ 1, 3, 4, 6 ]
    zero_count = remaining_positions.count { |index| days[index].planned_vertical_distance.zero? }
    assert_equal 1, zero_count
  end

  test "all day distances are multiples of 10 across week types" do
    %w[progression recovery taper goal].each do |category|
      week = Week.new(planned_vertical_distance: 3000, category: category)
      days = @generator.build_days(week, goal_vertical_distance = 3200)
      assert days.all? { |day| (day.planned_vertical_distance % 10).zero? }, "#{category} contained non-multiple of 10"
      assert_equal 3000, days.sum(&:planned_vertical_distance)
    end
  end
end
