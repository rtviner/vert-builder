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

  MINIMUM_VERTICAL_DISTANCE = 90
  MAX_EASY_PERCENTAGE = 0.15

  private
  # progression:
  #   total_hard_percentage = rand(0.75..0.80)
  #   easy_days_total = week.planned_vertical_distance.to_f * (1 - total_hard_percentage)
  #   max_easy = [ week_vert * MAX_EASY_PERCENTAGE, easy_days_total - (MINIMUM_VERTICAL_DISTANCE * 3) ].min
  #     randomize_days_with_sum(total: easy_days_total, count: 4, max: max_easy)
  # build_recovery_distribution:
  #     remaining_5_days_total = week.planned_vertical_distance.to_f * 0.40
  #     randomize_days_with_sum(total: remaining_5_days_total, count: 5, max:   week_vert * MAX_EASY_PERCENTAGE)
  # build_goal_normal_remaining:
  #   randomize_days_with_sum(total: remainder, count: 3, max: recovery_vert * MAX_EASY_PERCENTAGE)
  #
  BASELINE_UNITS_TABLE = {
    [ 4, 5 ] => { 600 => 9, 1000 => 15, Float::INFINITY => 20 },
    [ 3 ]    => { 600 => 15, Float::INFINITY => 20 }
  }.freeze

  def calculate_baseline_units(total, count)
    count_key = BASELINE_UNITS_TABLE.keys.find { |k| k.include?(count) }
    thresholds = BASELINE_UNITS_TABLE.fetch(count_key, { Float::INFINITY => 20 })
    thresholds.find { |threshold, _| total < threshold }.last
  end

  def randomize_days_with_sum(total:, count:, max:)
    raise ArgumentError, "count must be positive" if count <= 0

    total_units = (total / 10.0).round
    max_units = (max / 10.0).floor
    baseline_units = calculate_baseline_units(total, count)
    step_150_units = 15
    step_90_units = 9

    units = Array.new(count, baseline_units)
    remaining_units = total_units - baseline_units * count

    # Step down pass 1: baseline (200+) → 150
    while remaining_units < 0
      candidates = units.each_index.select { |i| units[i] > step_150_units }
      break if candidates.empty?
        idx = candidates.sample
        delta = units[idx] - step_150_units
        units[idx] = step_150_units
        remaining_units += delta
    end

    # Step down pass 2: 150 → 90
    while remaining_units < 0
      candidates = units.each_index.select { |i| units[i] == step_150_units }
      break if candidates.empty?
      units[candidates.sample] = step_90_units
      remaining_units += (step_150_units - step_90_units)
    end

    # Step down pass 3: 90 → 0 (only for count >= 5, last resort, max one zero day)
    if remaining_units < 0 && count >= 5
      candidates = units.each_index.select { |i| units[i] == step_90_units }
      unless candidates.empty?
        units[candidates.sample] = 0
        remaining_units += step_90_units
      end
    end

    # Step up: only items at 150 or above, never touch 90 or 0
    while remaining_units > 0
      candidates = units.each_index.select { |i| units[i] >= step_150_units && units[i] < max_units }
      break if candidates.empty?
      idx = candidates.sample
      step = [ rand(1..5), max_units - units[idx], remaining_units ].min
      next if step <= 0
      units[idx] += step
      remaining_units -= step
    end

    # Fallback: allow one 90 to absorb remainder if it lands in the 90-150 gap
    # zero days are never touched
    if remaining_units > 0
      candidates = units.each_index.select { |i| units[i] == step_90_units }
      unless candidates.empty?
        units[candidates.sample] += remaining_units
        remaining_units = 0
      end
    end

    raise ArgumentError, "could not distribute total #{total} across #{count} items" if remaining_units != 0

    units.shuffle.map { |unit| unit * 10 }
  end
end
