class PlanGenerator
  PlanResult = Struct.new(:success, :plan) do
    def success?
      success
    end
  end

  def initialize(plan)
    @plan = plan
    @weeks = []
    @days = []
  end

  def call
    @weeks = WeekGenerator.new(plan).build_weeks

    if @weeks.empty?
      return PlanResult.new(false, plan)
    end

    @weeks.each do |week|
      days.concat(DayGenerator.new.build_days(week, plan.goal_vertical_distance))
    end

    save_all
  rescue ArgumentError => e
    plan.errors.add(:base, "Day generation failed: #{e.message}")
    PlanResult.new(false, plan)
  end

  private

  attr_reader :plan, :weeks, :days

  def save_all
    ActiveRecord::Base.transaction do
      if plan.flexible_end_date? && weeks.any?
        plan.end_date = weeks.last.end_date
      end

      plan.save!
      weeks.each(&:save!)
      days.each(&:save!)
    end

    PlanResult.new(true, plan)
  rescue ActiveRecord::RecordInvalid => e
    plan.errors.add(:base, "Plan generation failed: #{e.message}")
    PlanResult.new(false, plan)
  rescue ActiveRecord::Rollback
    PlanResult.new(false, plan)
  end
end
