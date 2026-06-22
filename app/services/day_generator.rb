class DayGenerator
  MINIMUM_VERTICAL_DISTANCE = 90
  MAX_EASY_PERCENTAGE = 0.15

  private

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

  STEP_DOWN_TIERS = [ STEP_300_UNITS, STEP_200_UNITS, STEP_150_UNITS, STEP_90_UNITS ].freeze

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
    remaining_units = total_units - baseline_units * count

    # Step down pass: walk down through all step tiers until remaining_units >= 0
    remaining_units = step_down_to_balance(units, baseline_units, remaining_units)

    # Step down pass 3: 90 → 0 (only for count >= 5, last resort, max one zero day)
    if remaining_units < 0 && count >= 5
        step_down_unit(units, from: STEP_90_UNITS, to: 0)
        remaining_units += STEP_90_UNITS
    end

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
      candidates = units.each_index.select { |i| units[i] == STEP_90_UNITS }
      unless candidates.empty?
        units[candidates.sample] += remaining_units
        remaining_units = 0
      end
    end

    raise ArgumentError, "could not distribute total #{total} across #{count} items" if remaining_units != 0

    units.shuffle.map { |unit| unit * 10 }
  end
end
