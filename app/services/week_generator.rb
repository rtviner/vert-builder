class WeekGenerator
  RECOVERY_REDUCTION_PERCENTAGE = 40
  GOAL_WEEK_REDUCTION_PERCENTAGE = 60

  def initialize(plan)
    @plan = plan
  end

  def build_weeks
    return [] unless plan.valid?

    weeks = []
    progression_weeks = []
    week_number = 1

    until goal_condition_met?(progression_weeks)
      week = if recovery_week?(week_number)
               build_recovery_week(week_number, progression_weeks.last)
      else
               build_progression_week(week_number, progression_weeks.last)
      end

      progression_weeks << week if week.category == "progression"
      weeks << week
      week_number += 1
    end

    final_progression_week = progression_weeks.last

    taper_week = build_taper_week(week_number, final_progression_week)
    weeks << taper_week

    goal_week = build_goal_week(week_number + 1, final_progression_week)
    weeks << goal_week

    weeks
  end

  private

  attr_reader :plan

  def build_progression_week(week_number, previous_progression_week = nil)
    vertical_build_multiplier = 1 + plan.vertical_build_percentage / 100.0
    duration_build_multiplier = 1 + (Plan::MAX_PROGRESSION_PERCENTAGE - plan.vertical_build_percentage) / 100.0

    if previous_progression_week.present?
      planned_vertical_distance = (
        previous_progression_week.planned_vertical_distance * vertical_build_multiplier
      ).round(-1)
      planned_duration = (
        previous_progression_week.planned_duration * duration_build_multiplier
      ).round
    else
      planned_vertical_distance = (
        plan.baseline_vertical_distance * vertical_build_multiplier
      ).round(-1)
      planned_duration = (
        plan.baseline_duration * duration_build_multiplier
      ).round
    end

    Week.new(
      plan: plan,
      week_number: week_number,
      planned_vertical_distance: planned_vertical_distance,
      planned_duration: planned_duration,
      category: "progression",
      status: :planned,
      recovery_reduction_percentage: nil,
      vertical_build_percentage: plan.vertical_build_percentage
    )
  end

  def build_recovery_week(week_number, previous_progression_week)
    return nil if previous_progression_week.nil?

    recovery_reduction_multiplier = 1 - (RECOVERY_REDUCTION_PERCENTAGE / 100.0)

    planned_vertical_distance = (
      previous_progression_week.planned_vertical_distance * recovery_reduction_multiplier
    ).round(-1)
    planned_duration = (
      previous_progression_week.planned_duration * recovery_reduction_multiplier
    ).round

    Week.new(
      plan: plan,
      week_number: week_number,
      planned_vertical_distance: planned_vertical_distance,
      planned_duration: planned_duration,
      category: "recovery",
      status: :planned,
      recovery_reduction_percentage: RECOVERY_REDUCTION_PERCENTAGE,
      vertical_build_percentage: nil
    )
  end

  def build_taper_week(week_number, final_progression_week)
    recovery_reduction_multiplier = 1 - (RECOVERY_REDUCTION_PERCENTAGE / 100.0)
    planned_vertical_distance = (
      final_progression_week.planned_vertical_distance * recovery_reduction_multiplier
    ).round(-1)
    planned_duration = (
      final_progression_week.planned_duration * recovery_reduction_multiplier
    ).round

    Week.new(
      plan: plan,
      week_number: week_number,
      planned_vertical_distance: planned_vertical_distance,
      planned_duration: planned_duration,
      category: "taper",
      status: :planned,
      recovery_reduction_percentage: RECOVERY_REDUCTION_PERCENTAGE,
      vertical_build_percentage: nil
    )
  end

  def build_goal_week(week_number, final_progression_week)
    goal_week_reduction_multiplier = 1 - (GOAL_WEEK_REDUCTION_PERCENTAGE / 100.0)
    recovery_vertical_distance = (
      final_progression_week.planned_vertical_distance * goal_week_reduction_multiplier
    ).round(-1)
    planned_vertical_distance = recovery_vertical_distance + plan.goal_vertical_distance

    Week.new(
      plan: plan,
      week_number: week_number,
      planned_vertical_distance: planned_vertical_distance,
      planned_duration: nil,
      category: "goal",
      status: :planned,
      recovery_reduction_percentage: GOAL_WEEK_REDUCTION_PERCENTAGE,
      vertical_build_percentage: nil
    )
  end

  def recovery_week?(week_number)
    case plan.recovery_pattern.to_sym
    when :every_other then week_number.even?
    when :every_third then (week_number % 3).zero?
    when :every_fourth then (week_number % 4).zero?
    end
  end

  def goal_condition_met?(progression_weeks)
    return false if progression_weeks.length < 2

    progression_weeks.last(2).length == 2 &&
      progression_weeks.last(2).all? { |week| week.planned_vertical_distance >= plan.goal_vertical_distance }
  end
end
