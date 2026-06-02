# PlanGenerator Service — Prompt 1: Service Skeleton

## Context
- Service object lives at `app/services/plan_generator.rb`
- This prompt covers the service skeleton only
- `build_days` and `build_weeks` and controller are implemented later
- models are already implemented

## Console Usage
```ruby
plan = Plan.new(
  user: User.first,
  baseline_vertical_distance: 1624,
  baseline_duration: 180,
  goal_vertical_distance: 3300,
  start_date: Date.today,
  flexible_end_date: true,
)

result = PlanGenerator.new(plan).call
result.success?   # true or false
result.plan       # plan with associations if successful, errors if failed
```

## Service Implementation

```ruby
class PlanGenerator
  PlanResult = Struct.new(:success, :plan) do
    def success?
      success
    end
  end

  def initialize(plan)
    @plan  = plan
    @weeks = []
    @days  = []
  end

  def call
    build_weeks
    save_all
  end

  private

  def build_weeks
    # stub — implemented in Prompt 3
  end

  def build_days(week)
    # stub — implemented in Prompt 2
  end

  def save_all
    ActiveRecord::Base.transaction do
      @plan.save!
      @weeks.each(&:save!)
      @days.each(&:save!)
      @plan.update!(end_date: @weeks.last.end_date) if @plan.flexible_end_date?
    end
    PlanResult.new(true, @plan)
  rescue ActiveRecord::RecordInvalid => e
    @plan.errors.add(:base, "Plan generation failed: #{e.message}")
    PlanResult.new(false, @plan)
  rescue ActiveRecord::Rollback
    PlanResult.new(false, @plan)
  end
end
```

## Error Handling Rules
- Nothing touches the database until `save_all` is called
- If any record fails validation, `RecordInvalid` is rescued, the error message
  is added to `@plan.errors`, and `PlanResult.new(false, @plan)` is returned
- If an `ActiveRecord::Rollback` is raised, the transaction is rolled back and
  `PlanResult.new(false, @plan)` is returned
- No orphaned records — if generation fails nothing is written to the database

## Tests
Use Minitest and fixtures along with mock objects. Test the skeleton behavior only — week and day generation is stubbed so tests should not depend on their implementation.

### implement with minitest syntax

**Returns a PlanResult:**
```ruby
it "returns a PlanResult" do
  result = generator.call
  expect(result).to be_a(PlanGenerator::PlanResult)
end
```

**Returns success when plan is valid:**
```ruby
it "returns success? true when plan saves successfully" do
  result = generator.call
  expect(result.success?).to be true
end
```

**Returns the plan on the result:**
```ruby
it "returns the plan on the result" do
  result = generator.call
  expect(result.plan).to eq(plan)
end
```

**Saves the plan record:**
```ruby
it "saves the plan record" do
  expect { generator.call }.to change(Plan, :count).by(1)
end
```

**Does not save anything on failure:**
```ruby
it "does not save the plan if it is invalid" do
  plan.baseline_vertical_distance = nil
  result = generator.call
  expect(result.success?).to be false
  expect(Plan.count).to eq(0)
  expect(Week.count).to eq(0)
  expect(Day.count).to eq(0)
end
```

**Adds errors to the plan on failure:**
```ruby
it "adds errors to the plan on failure" do
  plan.baseline_vertical_distance = nil
  result = generator.call
  expect(result.plan.errors[:base]).to be_present
end
```

**Sets end_date on plan when flexible_end_date is true:**
```ruby
it "sets plan end_date after saving when flexible_end_date is true" do
  result = generator.call
  expect(result.plan.end_date).not_to be_nil
end
```

**Does not set end_date when flexible_end_date is false:**
```ruby
it "does not set plan end_date when flexible_end_date is false" do
  plan.flexible_end_date = false
  plan.end_date = Date.today + 90.days
  result = generator.call
  expect(result.plan.end_date).to eq(Date.today + 90.days)
end
```

**Transaction rolls back entirely on failure:**
```ruby
it "rolls back all records if any save fails" do
  allow_any_instance_of(Plan).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)
  generator.call
  expect(Plan.count).to eq(0)
  expect(Week.count).to eq(0)
  expect(Day.count).to eq(0)
end
```