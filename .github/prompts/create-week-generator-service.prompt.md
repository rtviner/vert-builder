# PlanGenerator Service — Prompt 3: Week Generation

## Context

- This prompt implements `build_weeks` and all private week building methods
- `build_days(week)` is already implemented and calls `DayGenerator.new.build_days(week, plan.goal_vertical_distance)`
- All week records are built in memory first, then saved in `save_all`
- Dates are NOT assigned during generation — they are assigned later when the plan is activated
- The plan is saved to the database at generation time with `status: :planned`

## Plan Model Fixes — Apply These Before Implementing Week Generation

### Fix 1 — vertical_build_percentage validation

```ruby
# wrong
validates :vertical_build_percentage, numericality: {
  greater_than_or_equal_to: 4,
  less_than_or_equal_to: MAX_PROGRESSION_PERCENTAGE
}

# correct
validates :vertical_build_percentage, numericality: {
  greater_than_or_equal_to: 4,
  less_than: MAX_PROGRESSION_PERCENTAGE  # strictly less than 15
}
```

## Week Model Fixes — Apply These Before Implementing Week Generation

### Fix 1 — enum status check

```ruby
# wrong
if: -> { status == "completed" }

# correct
if: -> { completed? }
```

### Fix 2 — date presence validation

```ruby
# wrong
validates :start_date, :end_date, presence: true

# correct
validates :start_date, :end_date, presence: true, if: -> { plan&.active? }
validate :end_date_after_start_date, if: -> { start_date.present? && end_date.present? }
```

### Fix 3 — add recovery_reduction_percentage column and validations

```ruby
# migration
add_column :weeks, :recovery_reduction_percentage, :integer, null: true, default: nil

# week.rb validations
# 0 for progression, 40-60 for recovery/taper, 60 for goal
validates :recovery_reduction_percentage,
          presence: true,
          numericality: {
            only_integer: true,
            greater_than_or_equal_to: 40,
            less_than_or_equal_to: 60
          },
          if: -> { category.in?(%w[recovery taper]) }

validates :recovery_reduction_percentage,
          absence: true,
          if: -> { category == "progression" }

validates :recovery_reduction_percentage,
          presence: true,
          numericality: { equal_to: 60 },
          if: -> { category == "goal" }
```

### Fix 4 — add vertical_build_percentage column and validations

```ruby
# migration
add_column :weeks, :vertical_build_percentage, :integer, null: true, default: nil

# week.rb
validates :vertical_build_percentage,
          numericality: {
            greater_than_or_equal_to: 4,
            less_than: Plan::MAX_PROGRESSION_PERCENTAGE
          },
          if: -> { category == "progression" }

validates :vertical_build_percentage,
          absence: true,
          if: -> { category.in?(%w[recovery taper goal]) }
```

## Generator Constants

```ruby
MINIMUM_BASELINE_VERT          = 1000
RECOVERY_REDUCTION_PERCENTAGE  = 40
GOAL_WEEK_REDUCTION_PERCENTAGE = 60
```

## Rounding Rules

```ruby
# planned_vertical_distance — round to nearest 10
planned_vertical_distance.round(-1)

# planned_duration — round to nearest integer
planned_duration.round
```

## Plan Structure

### recovery pattern every other

```
Progression week 1
Recovery week 1
Progression week 2
Recovery week 2
...repeat until goal condition met...
Progression week X     → planned_vertical_distance >= goal_vertical_distance (1st)
Recovery week X        → regular recovery rules
Progression week X+1   → planned_vertical_distance >= goal_vertical_distance (2nd) ← stop cycle
Taper week             → special rules
Goal/Peak week         → special rules
```

### recovery pattern every third

```
Progression week 1
Progression week 2
Recovery week 1
Progression week 3
Progression week 4
Recovery week 2
...repeat until goal condition met...
Progression week X     → planned_vertical_distance >= goal_vertical_distance (1st)
Progression week X+1   → planned_vertical_distance >= goal_vertical_distance (2nd) ← stop cycle
Taper week             → special rules
Goal/Peak week         → special rules
```

### recovery pattern every fourth

```
Progression week 1
Progression week 2
Progression week 3
Recovery week 1
Progression week 4
Progression week 5
Progression week 6
Recovery week 2
...repeat until goal condition met...
Progression week X     → planned_vertical_distance >= goal_vertical_distance (1st)
Progression week X+1   → planned_vertical_distance >= goal_vertical_distance (2nd) ← stop cycle
Taper week             → special rules
Goal/Peak week         → special rules
```

## Minimum Baseline Vert Validation

```ruby
def validate_minimum_baseline_vert
  if plan.baseline_vertical_distance < MINIMUM_BASELINE_VERT
    plan.errors.add(:baseline_vertical_distance,
      "must be at least #{MINIMUM_BASELINE_VERT}ft to generate a plan")
    return false
  end
  true
end
```

## Recovery Pattern

```ruby
def recovery_week?(week_number)
  case plan.recovery_pattern.to_sym
  when :every_other  then week_number.even?
  when :every_third  then (week_number % 3).zero?
  when :every_fourth then (week_number % 4).zero?
  end
end
```

## Goal Condition

```ruby
def goal_condition_met?(progression_weeks)
  progression_weeks.last(2).length == 2 &&
    progression_weeks.last(2).all? { |w| w.planned_vertical_distance >= plan.goal_vertical_distance }
end
```

## Week Building Rules

### `build_progression_week`

```ruby
# week 1 — no previous progression week
planned_vertical_distance =
  (plan.baseline_vertical_distance * (1 + plan.vertical_build_percentage / 100.0)).round(-1)

duration_build_percentage     = MAX_PROGRESSION_PERCENTAGE - plan.vertical_build_percentage
planned_duration = (
  plan.baseline_duration * (1 + duration_build_percentage / 100.0)
).round

vertical_build_percentage     = plan.vertical_build_percentage
category                      = "progression"
status                        = :upcoming
recovery_reduction_percentage = nil

# subsequent progression weeks — use previous week's volumes multiplied by
# THIS week's vertical_build_percentage (which defaults to plan default)
vertical_build_percentage = plan.vertical_build_percentage

planned_vertical_distance = (
  previous_progression_week.planned_vertical_distance * (1 + vertical_build_percentage / 100.0)
).round(-1)

duration_build_percentage     = MAX_PROGRESSION_PERCENTAGE - vertical_build_percentage
planned_duration = (
  previous_progression_week.planned_duration *
    (1 + duration_build_percentage / 100.0)
).round

category                      = "progression"
status                        = :upcoming
recovery_reduction_percentage = nil
vertical_build_percentage     = vertical_build_percentage
```

### `build_recovery_week`

```ruby
recovery_reduction_percentage = RECOVERY_REDUCTION_PERCENTAGE  # 0.40, user can update later
planned_vertical_distance =
  (previous_progression_week.planned_vertical_distance * (1 - recovery_reduction_percentage)
).round(-1)
planned_duration = (previous_progression_week.planned_duration * (1 - recovery_reduction_percentage)).round

category                      = "recovery"
status                        = :upcoming
recovery_reduction_percentage = revcovery_reduction_percentage
vertical_build_percentage     = nil
```

### `build_taper_week`

```ruby
recovery_reduction_percentage = RECOVERY_REDUCTION_PERCENTAGE  # 0.40, user can update later
planned_vertical_distance =
  (final_progression_week.planned_vertical_distance * (1 - recovery_reduction_percentage)
).round(-1)
planned_duration = (final_progression_week.planned_duration * (1 - recovery_reduction_percentage)).round

category                      = "taper"
status                        = :upcoming
recovery_reduction_percentage = recovery_reduction_percentage
vertical_build_percentage     = nil
```

### `build_goal_week`

```ruby
recovery_vertical_distance = (final_progression_week.planned_vertical_distance * 0.40).round(-1)
planned_vertical_distance = recovery_vertical_distance + plan.goal_vertical_distance
planned_duration          = nil  # duration is not relevant for goal week

category                      = "goal"
status                        = :upcoming
recovery_reduction_percentage = GOAL_WEEK_REDUCTION_PERCENTAGE  # 0.60, fixed
vertical_build_percentage     = vertical_build_percentage
```

## `build_weeks` Logic

```ruby
def build_weeks
  return unless validate_minimum_baseline_vert

  progression_weeks = []
  week_number       = 1

  until goal_condition_met?(progression_weeks)
    week = if recovery_week?(week_number)
             build_recovery_week(week_number, progression_weeks.last)
           else
             build_progression_week(week_number, progression_weeks.last)
           end

    progression_weeks << week if week.category == "progression"
    weeks << week
    build_days(week)
    week_number += 1
  end

  final_progression_week = progression_weeks.last

  taper_week = build_taper_week(week_number, final_progression_week)
  weeks << taper_week
  build_days(taper_week)

  goal_week = build_goal_week(week_number + 1, final_progression_week)
  weeks << goal_week
  build_days(goal_week)
end
```

## Private Method Structure

```ruby
def build_weeks
def build_progression_week(week_number, previous_progression_week = nil)
def build_recovery_week(week_number, previous_progression_week)
def build_taper_week(week_number, final_progression_week)
def build_goal_week(week_number, final_progression_week)
def recovery_week?(week_number)
def goal_condition_met?(progression_weeks)
def validate_minimum_baseline_vert
def duration_build_percentage
```

## Fixtures

```yaml
# test/fixtures/users.yml
alice:
  email_address: alice@example.com
  password_digest: <%= BCrypt::Password.create("password") %>

# test/fixtures/plans.yml
med_basic_plan:
  user: alice
  baseline_vertical_distance: 2500
  baseline_duration: 280
  goal_vertical_distance: 7250
  flexible_end_date: true
  recovery_pattern: 0
  vert_build_percentage: 10
  status: 0

low_baseline_plan:
  user: alice
  baseline_vertical_distance: 1200
  baseline_duration: 120
  goal_vertical_distance: 2800
  flexible_end_date: true
  recovery_pattern: 2
  vert_build_percentage: 10
  status: 0
```

## Tests

```ruby
# test/services/plan_generator_week_generation_test.rb
require "test_helper"

class PlanGeneratorWeekGenerationTest < ActiveSupport::TestCase
  def setup
    @user = users(:alice)
  end

  def build_plan(overrides = {})
    Plan.new({
      user: @user,
      baseline_vertical_distance: 1624,
      baseline_duration: 180,
      goal_vertical_distance: 3300,
      flexible_end_date: true,
      recovery_pattern: :every_other,
      vert_build_percentage: 10,
      status: :planned
    }.merge(overrides))
  end

  def generator(plan)
    PlanGenerator.new(plan)
  end

  # --- Minimum baseline vert ---

  test "fails if baseline_vertical_distance is below minimum" do
    plan   = build_plan(baseline_vertical_distance: 500)
    result = generator(plan).call
    assert_not result.success?
    assert result.plan.errors[:baseline_vertical_distance].any?
  end

  test "succeeds if baseline_vertical_distance meets minimum" do
    plan   = build_plan(baseline_vertical_distance: 1200)
    result = generator(plan).call
    assert result.success?
  end

  # --- Minimum plan length ---

  test "generates a minimum of 5 weeks" do
    result = generator(build_plan).call
    assert result.plan.weeks.count >= 5
  end

  # --- Plan structure ---

  test "second to last week is taper" do
    result = generator(build_plan).call
    assert_equal "taper", result.plan.weeks.order(:week_number).second_to_last.category
  end

  test "last week is goal" do
    result = generator(build_plan).call
    assert_equal "goal", result.plan.weeks.order(:week_number).last.category
  end

  # --- Goal condition ---

  test "last 2 progression weeks before taper meet or exceed goal vert" do
    result = generator(build_plan).call
    progression_weeks = result.plan.weeks
                              .order(:week_number)
                              .to_a[0..-3]
                              .select { |w| w.category == "progression" }
    assert progression_weeks.last(2).all? { |w|
      w.planned_vertical_distance >= result.plan.goal_vertical_distance
    }
  end

  # --- Progression week vert ---

  test "week 1 vert is calculated from baseline and vert_build_percentage" do
    plan   = build_plan
    result = generator(plan).call
    week_1 = result.plan.weeks.find_by(week_number: 1)
    expected = (plan.baseline_vertical_distance * 1.10 / 10.0).round * 10
    assert_equal expected, week_1.planned_vertical_distance
  end

  test "each progression week vert increases from previous progression week planned vertical distance" do
    plan   = build_plan
    result = generator(plan).call
    progression_weeks = result.plan.weeks
                              .order(:week_number)
                              .select { |w| w.category == "progression" }
    progression_weeks.each_cons(2) do |prev, curr|
      expected = (prev.planned_vertical_distance * 1.10 / 10.0).round * 10
      assert_equal expected, curr.planned_vertical_distance
    end
  end

  # --- Progression week duration ---
test "duration and vertical distance increases from previous progression week no more than MAX_PROGRESSION_PERCENTAGE" do
    plan   = build_plan
    result = generator(plan).call
    progression_weeks = result.plan.weeks
                              .order(:week_number)
                              .select { |w| w.category == "progression" }
    progression_weeks.each_cons(2) do |prev, curr|
      max_duration_progression_percentage = 0.15 - prev.vert_build_percentage
      expected = (prev.planned_duration * (1 + max_duration_progression_percentage)).round
      assert_equal expected, curr.planned_duration
    end
  end

  # --- Recovery week vert ---

  test "recovery week vert reduces by recovery_reduction_percentage from previous progression week" do
    result = generator(build_plan).call
    weeks  = result.plan.weeks.order(:week_number).to_a
    weeks.each_with_index do |week, idx|
      next unless week.category == "recovery"
      prev_prog = weeks[0..idx - 1].reverse.find { |w| w.category == "progression" }
      expected  = (prev_prog.planned_vertical_distance * 0.60 / 10.0).round * 10
      assert_equal expected, week.planned_vertical_distance
    end
  end

  test "recovery weeks have recovery_reduction_percentage of at least 0.40" do
    result = generator(build_plan).call
    result.plan.weeks.where(category: "recovery").each do |week|
      assert_operator week.recovery_reduction_percentage.to_f, :>=, 0.40
    end
  end

  # --- Recovery week duration ---
  test "recovery week duration reduces by recovery_reduction_percentage from previous progression week" do
    result = generator(build_plan).call
    weeks  = result.plan.weeks.order(:week_number).to_a
    weeks.each_with_index do |week, idx|
      next unless week.category == "recovery"
      prev_prog = weeks[0..idx - 1].reverse.find { |w| w.category == "progression" }
      expected  = (prev_prog.planned_duration * 0.60).round
      assert_equal expected, week.planned_duration
    end
  end

  # --- Taper week ---

  test "taper week vert reduces by recovery_reduction_percentage from final progression week" do
    result     = generator(build_plan).call
    weeks      = result.plan.weeks.order(:week_number).to_a
    taper      = weeks[-2]
    final_prog = weeks[0..-3].reverse.find { |w| w.category == "progression" }
    expected   = (final_prog.planned_vertical_distance * 0.60 / 10.0).round * 10
    assert_equal expected, taper.planned_vertical_distance
  end

  test "taper week duration reduces by recovery_reduction_percentage from final progression week" do
    result     = generator(build_plan).call
    weeks      = result.plan.weeks.order(:week_number).to_a
    taper      = weeks[-2]
    final_prog = weeks[0..-3].reverse.find { |w| w.category == "progression" }
    expected   = (final_prog.planned_duration * 0.60).round
    assert_equal expected, taper.planned_duration
  end

  test "taper week has recovery_reduction_percentage of at least 0.40" do
    result = generator(build_plan).call
    taper  = result.plan.weeks.find_by(category: "taper")
    assert_operator taper.recovery_reduction_percentage.to_f, :>=, 0.40
  end

  # --- Goal week ---

  test "goal week planned_vertical_distance is recovery vert plus goal vert" do
    plan   = build_plan
    result = generator(plan).call
    weeks      = result.plan.weeks.order(:week_number).to_a
    goal_week  = weeks.last
    final_prog = weeks[0..-3].reverse.find { |w| w.category == "progression" }
    recovery_vert = (final_prog.planned_vertical_distance * 0.40 / 10.0).round * 10
    expected      = recovery_vert + plan.goal_vertical_distance
    assert_equal expected, goal_week.planned_vertical_distance
  end

  test "goal week has recovery_reduction_percentage of 0.60" do
    result = generator(build_plan).call
    assert_operator result.plan.weeks.find_by(category: "goal").recovery_reduction_percentage.to_f, :>=, 0.60
  end

  test "goal week have null planned duration" do
    result = generator(build_plan).call
    assert_nil result.plan.weeks.find_by(category: "goal").planned_duration
  end

  # --- Progression week recovery_reduction_percentage ---

  test "progression weeks have null recovery_reduction_percentage" do
    result = generator(build_plan).call
    result.plan.weeks.where(category: "progression").each do |week|
      assert_nil week.recovery_reduction_percentage
    end
  end

  # --- Recovery pattern ---

  test "every_other pattern alternates progression and recovery weeks" do
    result = generator(build_plan(recovery_pattern: :every_other)).call
    weeks  = result.plan.weeks.order(:week_number).to_a[0..-3]
    weeks.each_with_index do |week, idx|
      expected = (idx + 1).even? ? "recovery" : "progression"
      assert_equal expected, week.category
    end
  end

  test "every_third pattern places recovery every third week" do
    result = generator(build_plan(recovery_pattern: :every_third)).call
    weeks  = result.plan.weeks.order(:week_number).to_a[0..-3]
    weeks.each_with_index do |week, idx|
      expected = ((idx + 1) % 3).zero? ? "recovery" : "progression"
      assert_equal expected, week.category
    end
  end

  test "every_fourth pattern places recovery every fourth week" do
    result = generator(build_plan(recovery_pattern: :every_fourth)).call
    weeks  = result.plan.weeks.order(:week_number).to_a[0..-3]
    weeks.each_with_index do |week, idx|
      expected = ((idx + 1) % 4).zero? ? "recovery" : "progression"
      assert_equal expected, week.category
    end
  end

  # --- Week numbering ---

  test "week numbers are sequential starting from 1" do
    result       = generator(build_plan).call
    week_numbers = result.plan.weeks.order(:week_number).pluck(:week_number)
    assert_equal (1..week_numbers.count).to_a, week_numbers
  end

  # --- No dates assigned during generation ---

  test "weeks have no start_date or end_date after generation" do
    result = generator(build_plan).call
    result.plan.weeks.each do |week|
      assert_nil week.start_date
      assert_nil week.end_date
    end
  end

  # --- Plan saved with planned status ---

  test "plan is persisted with planned status after generation" do
    result = generator(build_plan).call
    assert result.plan.persisted?
    assert result.plan.planned?
  end

  test "plan has no start or end date after generation" do
    result = generator(build_plan).call
    assert_nil result.plan.start_date
    assert_nil result.plan.end_date
  end
end
```
