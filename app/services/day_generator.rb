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

  def build_recovery_distribution(week)
    week_vert = week.planned_vertical_distance.to_f
    long_day = week_vert * 0.40
    medium_day = week_vert * 0.20
    remaining_5_days_total = week_vert * 0.40

    remaining_5 = if remaining_5_days_total / 5.0 >= MINIMUM_VERTICAL_DISTANCE
      randomize_days_with_sum(total: remaining_5_days_total, count: 5, min: MINIMUM_VERTICAL_DISTANCE, max: week_vert * MAX_EASY_PERCENTAGE)
    else
      build_recovery_fallback_remaining(remaining_5_days_total)
    end

    { long_day: long_day, medium_day: medium_day, remaining_5: remaining_5 }
  end

  private


MINIMUM_VERTICAL_DISTANCE = 90
MAX_EASY_PERCENTAGE = 0.15

  def build_progression_days(week)
    week_vert = week.planned_vertical_distance.to_f
    total_hard_percentage = rand(0.75..0.80)
    long_day_percentage = 0.35
    long_day = week_vert * long_day_percentage
    hard_day_2_percentage = rand(0.20..0.25)
    hard_day_2 = week_vert * hard_day_2_percentage
    hard_day_3 = week_vert * (total_hard_percentage - long_day_percentage - hard_day_2_percentage)
    easy_days_total = week_vert * (1 - total_hard_percentage)

    easy_days = if easy_days_total >= 4 * MINIMUM_VERTICAL_DISTANCE
      max_easy = [ week_vert * MAX_EASY_PERCENTAGE, easy_days_total - (MINIMUM_VERTICAL_DISTANCE * 3) ].min
      randomize_days_with_sum(total: easy_days_total, count: 4, min: MINIMUM_VERTICAL_DISTANCE, max: max_easy)
    else
      [ 0.0 ] + Array.new(3, easy_days_total / 3.0)
    end

    [
      DaySpec.new(:easy, easy_days[0]),
      DaySpec.new(:hard, hard_day_2),
      DaySpec.new(:easy, easy_days[1]),
      DaySpec.new(:long, long_day),
      DaySpec.new(:easy, easy_days[2]),
      DaySpec.new(:hard, hard_day_3),
      DaySpec.new(:easy, easy_days[3])
    ]
  end

  def build_recovery_days(week)
    distribution = build_recovery_distribution(week)
    day_specs = distribution[:remaining_5].map { |distance| DaySpec.new(:remaining, distance) }
    day_specs << DaySpec.new(:long, distribution[:long_day])
    day_specs << DaySpec.new(:medium, distribution[:medium_day])
    shuffled = day_specs.shuffle
    ensure_long_medium_not_adjacent!(shuffled)
    shuffled
  end

  def build_taper_days(week)
    distribution = build_recovery_distribution(week)
    remaining = distribution[:remaining_5].shuffle

    [
      DaySpec.new(:long, distribution[:long_day]),
      DaySpec.new(:remaining, remaining.shift),
      DaySpec.new(:medium, distribution[:medium_day])
    ] + remaining.map { |distance| DaySpec.new(:remaining, distance) }
  end

  def build_goal_days(week, goal_vertical_distance)
    week_vert = week.planned_vertical_distance.to_f
    recovery_vertical_distance = week_vert - goal_vertical_distance
    long_day = recovery_vertical_distance * 0.40
    medium_day = recovery_vertical_distance * 0.20
    goal_day = goal_vertical_distance
    remaining_4_days_total = recovery_vertical_distance * 0.40

    remaining_days = if remaining_4_days_total / 4.0 >= MINIMUM_VERTICAL_DISTANCE
      build_goal_normal_remaining(remaining_4_days_total, recovery_vertical_distance)
    else
      build_goal_fallback_remaining(remaining_4_days_total)
    end

    [
      DaySpec.new(:long, long_day),
      DaySpec.new(:remaining, remaining_days.shift),
      DaySpec.new(:medium, medium_day),
      DaySpec.new(:remaining, remaining_days.shift),
      DaySpec.new(:remaining, remaining_days.shift),
      DaySpec.new(:goal, goal_day),
      DaySpec.new(:remaining, remaining_days.shift)
    ]
  end

  def build_day_records(week, day_specs)
    rounded_values = balance_rounding!(day_specs, week.planned_vertical_distance)

    day_specs.each_with_index.map do |spec, index|
      Day.new(
        week: week,
        planned_vertical_distance: rounded_values[index],
        status: :upcoming
      )
    end
  end

  def balance_rounding!(day_specs, week_total)
    rounded_values = day_specs.map { |spec| round_to_nearest_10(spec.planned_vertical_distance) }
    remainder = week_total - rounded_values.sum
    adjustment_index = day_specs.index { |spec| spec.type == :easy || spec.type == :remaining } || 0
    rounded_values[adjustment_index] += remainder
    rounded_values
  end

  def build_recovery_normal_remaining(total, week_vert)
    randomize_days_with_sum(total: remainder, count: 5, min: MINIMUM_VERTICAL_DISTANCE, max: week_vert * MAX_EASY_PERCENTAGE)
  end

  def build_recovery_fallback_remaining(total)
    [ 0 ] + build_variation_remaining(total, 4)
  end

  def build_goal_normal_remaining(total, recovery_vert)
    one_day = [ 90, 100 ].sample
    remainder = total - one_day
    remaining = randomize_days_with_sum(total: remainder, count: 3, min: 0, max: recovery_vert * MAX_EASY_PERCENTAGE)
    [ one_day ] + remaining
  end

  def build_goal_fallback_remaining(total)
    [ 0 ] + build_variation_remaining(total, 3)
  end

  def build_variation_remaining(total, count)
    average = total.to_f / count
    values = if average >= 100
      apply_variation(values: Array.new(count, average), range: 50..100)
    else
      Array.new(count, average)
    end

    rounded = values.map { |value| round_to_nearest_10([ value, 0 ].max) }
    remainder = total - rounded.sum
    rounded[0] += remainder
    rounded
  end

  def ensure_long_medium_not_adjacent!(day_specs)
    long_index = day_specs.index { |spec| spec.type == :long }
    medium_index = day_specs.index { |spec| spec.type == :medium }
    return unless long_index && medium_index
    return unless (long_index - medium_index).abs == 1

    swap_pair = day_specs.each_with_index.find do |spec, index|
      next false if [ long_index, medium_index ].include?(index)
      next false if [ long_index - 1, long_index + 1 ].include?(index)
      spec.type != :long && spec.type != :medium
    end

    swap_index = swap_pair&.last
    return unless swap_index

    day_specs[medium_index], day_specs[swap_index] = day_specs[swap_index], day_specs[medium_index]
  end

  def randomize_days_with_sum(total:, count:, min:, max:)
    raise ArgumentError, "count must be positive" if count <= 0

    total_units = (total / 10.0).round
    min_units = (min / 10.0).ceil
    max_units = (max / 10.0).floor
    raise ArgumentError, "cannot satisfy bounds" if min_units * count > total_units || max_units * count < total_units

    units = Array.new(count, min_units)
    remaining_units = total_units - min_units * count

    while remaining_units > 0
      index = rand(count)
      allocatable = [ max_units - units[index], remaining_units ].min
      next if allocatable <= 0

      addition = rand(1..allocatable)
      units[index] += addition
      remaining_units -= addition
    end

    units = merge_one_min_into_another(units, min_units, max_units)
    units.shuffle.map { |unit| unit * 10 }
  end

  def merge_one_min_into_another(units, min_units, max_units)
    min_idxs = units.each_index.select { |i| units[i] == min_units }
    return units if min_idxs.size < 2

    # try find a pair where receiver won't exceed max
    min_idxs.combination(2).each do |a, b|
      if units[a] + units[b] <= max_units
        units[a] += units[b]
        units[b] = 0
        return units
      elsif units[b] + units[a] <= max_units
        units[b] += units[a]
        units[a] = 0
        return units
      end
    end

    # fallback: merge into the min index that produces the smallest overflow (will exceed max)
    a, b = min_idxs.first(2)
    units[a] += units[b]
    units[b] = 0
    units
  end

  def apply_variation(values:, range:)
    return values if values.empty?

    total = values.sum
    deltas = values.map do
      rand(range.min..range.max) - ((range.min + range.max) / 2.0)
    end
    adjustment = deltas.sum / deltas.size
    adjusted = values.each_with_index.map do |value, index|
      value + deltas[index] - adjustment
    end
    scale = total / adjusted.sum
    adjusted.map { |value| value * scale }
  end

  def round_to_nearest_10(value)
    (value / 10.0).round * 10
  end
end
