class PlanExtender
  PlanResult = Struct.new(:success, :plan) do
    def success?
      success
    end
  end

  def initialize(plan, target_end_date)
    @plan = plan
    @target_end_date = target_end_date
  end

  def call
    validate!

    result = nil

    plan.transaction do
      delete_taper_and_goal_weeks!

      weeks_to_add = generate_new_weeks

      if weeks_to_add.empty?
        result = PlanResult.new(false, plan)
        raise ActiveRecord::Rollback
      end

      days_to_add = begin
        weeks_to_add.flat_map { |week| DayGenerator.new.build_days(week, plan.goal_vertical_distance) }
      rescue ArgumentError => e
        plan.errors.add(:base, "Day generation failed: #{e.message}")
        result = PlanResult.new(false, plan)
        raise ActiveRecord::Rollback
      end

      weeks_to_add.each(&:save!)
      days_to_add.each(&:save!)
      plan.update!(end_date: weeks_to_add.last.end_date)

      result = PlanResult.new(true, plan)
    end

    result
  end

  private

  attr_reader :plan, :target_end_date

  def validate!
    raise ArgumentError, "plan has no dates to extend from" unless plan.extendable?
    raise ArgumentError, "target_end_date must be after the plan's current end_date" if target_end_date <= plan.end_date
  end

  def delete_taper_and_goal_weeks!
    plan.weeks.find_by(category: :taper)&.destroy!
    plan.weeks.find_by(category: :goal)&.destroy!
  end

  def generate_new_weeks
    existing_progression_weeks = plan.weeks.where(category: :progression).order(:week_number).to_a
    resume_week_number = plan.weeks.maximum(:week_number) + 1

    WeekGenerator.new(
      plan,
      starting_week_number: resume_week_number,
      starting_progression_weeks: existing_progression_weeks,
      target_end_date: target_end_date
    ).build_weeks
  end
end
