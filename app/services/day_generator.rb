class DayGenerator
  DaySpec = Struct.new(:type, :planned_vertical_distance)

  def build_days(week, goal_vertical_distance)
    day_specs = case week.category
    when "progression"
      build_progression_days(week)
    when "recovery"
      build_recovery_days(week)
    when "taper"
      build_taper_days(week)
    when "goal"
      build_goal_days(week, goal_vertical_distance)
    else
      raise ArgumentError, "Unknown week category #{week.category.inspect}"
    end

    build_day_records(week, day_specs)
  end

  private

  MINIMUM_VERTICAL_DISTANCE = 90
  MAX_EASY_PERCENTAGE = 0.15

  STEP_150_UNITS = 15
  STEP_90_UNITS = 9
  STEP_200_UNITS = 20
  STEP_300_UNITS = 30
  STEP_400_UNITS = 40

  BASELINE_UNITS_TABLE = {
    [ 4, 5 ] => {
      600           => STEP_90_UNITS,
      1000          => STEP_150_UNITS,
      5000          => STEP_200_UNITS,
      9000          => STEP_300_UNITS,
      Float::INFINITY => STEP_400_UNITS
    },
    [ 3 ] => {
      600           => STEP_150_UNITS,
      5000          => STEP_200_UNITS,
      9000          => STEP_300_UNITS,
      Float::INFINITY => STEP_400_UNITS
    }
  }.freeze

  def calculate_baseline_units(total, count)
    count_key = BASELINE_UNITS_TABLE.keys.find { |k| k.include?(count) }
    thresholds = BASELINE_UNITS_TABLE.fetch(count_key, { Float::INFINITY => STEP_200_UNITS })
    thresholds.find { |threshold, _| total < threshold }.last
  end

  def step_down_unit(units, from:, to:)
    candidates = units.each_index.select { |i| units[i] == from }
    return false if candidates.empty?
    units[candidates.sample] = to
    true
  end

  STEP_DOWN_TIERS = [ STEP_300_UNITS, STEP_200_UNITS, STEP_150_UNITS, STEP_90_UNITS, 0 ].freeze

  def step_down_to_balance(units, baseline_units, remaining_units)
    tiers = STEP_DOWN_TIERS.select { |tier| tier < baseline_units }

    tiers.each do |tier|
      break if remaining_units >= 0
      delta = baseline_units - tier

      while remaining_units < 0
        break unless step_down_unit(units, from: baseline_units, to: tier)
        remaining_units += delta
      end

      baseline_units = tier
    end

    remaining_units
  end

  def randomize_days_with_sum(total:, count:, max:)
    raise ArgumentError, "count must be positive" if count <= 0

    total_units = (total / 10.0).round
    max_units = (max / 10.0).floor
    baseline_units = calculate_baseline_units(total, count)

    units = Array.new(count, baseline_units)
    remaining_units = total_units - (baseline_units * count)

    # Step down pass: walk down through all step tiers until remaining_units >= 0
    remaining_units =  step_down_to_balance(units, baseline_units, remaining_units) unless remaining_units >= 0

    # Step up: only items at 150 or above, never touch 90 or 0
    while remaining_units > 0
      candidates = units.each_index.select { |i| units[i] >= STEP_150_UNITS && units[i] < max_units }
      break if candidates.empty?

      idx = candidates.sample
      step = [ rand(1..5), max_units - units[idx], remaining_units ].min
      units[idx] += step
      remaining_units -= step
    end

    # Fallback: allow one 90 to absorb remainder if it lands in the 90-150 gap
    # zero days are never touched
    if remaining_units > 0
      candidates = units.each_index.select { |i| units[i] == STEP_90_UNITS && units[i] < max_units }
      unless candidates.empty?
        idx = candidates.sample
        step = [ remaining_units, max_units - units[idx] ].min
        units[idx] += step
        remaining_units -= step
      end
    end

    if remaining_units > count || remaining_units < -count
      raise ArgumentError, "could not distribute total #{total} across #{count} items"
    end

    units.shuffle.map { |unit| unit * 10 }
  end

  def build_recovery_distribution(week)
      week_vert = week.planned_vertical_distance.to_f

      long_day = (week_vert * 0.40).round(-1)
      medium_day = (week_vert * 0.20).round(-1)

      easy_5_days_total = week_vert - long_day - medium_day
      easy_5_days = randomize_days_with_sum(total: easy_5_days_total, count: 5, max: week_vert * MAX_EASY_PERCENTAGE)

      { long_day: long_day, medium_day: medium_day, easy_5_days: easy_5_days }
  end

  def build_progression_days(week)
    week_vert = week.planned_vertical_distance.to_f
    total_hard_percentage = rand(0.75..0.80)

    long_day_percentage = 0.35
    long_day = (week_vert * long_day_percentage).round(-1)

    hard_day_2_percentage = rand(0.20..0.25)
    hard_day_2 = (week_vert * hard_day_2_percentage).round(-1)

    hard_day_3 = (week_vert * (total_hard_percentage - long_day_percentage - hard_day_2_percentage)).round(-1)

    easy_4_days_total = week_vert - long_day - hard_day_2 - hard_day_3
    easy_4_days = randomize_days_with_sum(total: easy_4_days_total, count: 4, max: week_vert * MAX_EASY_PERCENTAGE)

    [
      DaySpec.new(:easy, easy_4_days[0]),
      DaySpec.new(:hard, hard_day_2),
      DaySpec.new(:easy, easy_4_days[1]),
      DaySpec.new(:long, long_day),
      DaySpec.new(:easy, easy_4_days[2]),
      DaySpec.new(:hard, hard_day_3),
      DaySpec.new(:easy, easy_4_days[3])
    ]
  end

  def build_recovery_days(week)
    distribution = build_recovery_distribution(week)
    easy_5_days = distribution[:easy_5_days].shuffle

    [
      DaySpec.new(:easy, easy_5_days.shift),
      DaySpec.new(:easy, easy_5_days.shift),
      DaySpec.new(:long, distribution[:long_day]),
      DaySpec.new(:easy, easy_5_days.shift),
      DaySpec.new(:easy, easy_5_days.shift),
      DaySpec.new(:medium, distribution[:medium_day]),
      DaySpec.new(:easy, easy_5_days.shift)
    ]
  end

  def build_taper_days(week)
    distribution = build_recovery_distribution(week)
    easy_5_days = distribution[:easy_5_days].shuffle

    [
      DaySpec.new(:long, distribution[:long_day]),
      DaySpec.new(:easy, easy_5_days.shift),
      DaySpec.new(:medium, distribution[:medium_day])
    ] + easy_5_days.map { |distance| DaySpec.new(:easy, distance) }
  end

  def build_goal_days(week, goal_vertical_distance)
    week_vert = week.planned_vertical_distance.to_f
    recovery_vertical_distance = week_vert - goal_vertical_distance

    long_day = (recovery_vertical_distance * 0.40).round(-1)
    medium_day = (recovery_vertical_distance * 0.20).round(-1)
    goal_day = goal_vertical_distance

    easy_4_days_total = recovery_vertical_distance - long_day - medium_day
    easy_4_days = randomize_days_with_sum(
        total: easy_4_days_total,
        count: 4,
        max: recovery_vertical_distance * MAX_EASY_PERCENTAGE
      )

    [
      DaySpec.new(:long, long_day),
      DaySpec.new(:easy, easy_4_days[0]),
      DaySpec.new(:medium, medium_day),
      DaySpec.new(:easy, easy_4_days[1]),
      DaySpec.new(:easy, easy_4_days[2]),
      DaySpec.new(:goal, goal_day),
      DaySpec.new(:easy, easy_4_days[3])
    ]
  end

  def build_day_records(week, day_specs)
    day_specs.each_with_index.map do |spec, index|
      Day.new(
        week: week,
        planned_vertical_distance: (day_specs[index].planned_vertical_distance),
        status: :upcoming
      )
    end
  end
end
