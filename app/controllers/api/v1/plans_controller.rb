class Api::V1::PlansController < ApplicationController
  def activate
    plan = Current.user.plans.find(params[:id])
    plan.start_plan!(start_date_param: params[:start_date])
    render json: plan_detail(plan), status: :ok
  rescue ArgumentError => e
    render json: { error: { status: 400, message: "Bad request", detail: e.message } }, status: :bad_request
  end

  def create
    plan = Current.user.plans.new(plan_params)
    result = PlanGenerator.new(plan).call
    if result.success?
      render json: plan, status: :created
    else
      render json: { errors: result.plan.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def index
    plans = Current.user.plans

    if params[:status].present?
      unless Plan.statuses.key?(params[:status])
        return render json: {
          error: {
            status: 422,
            message: "Validation failed",
            errors: [ "status must be one of: #{Plan.statuses.keys.join(', ')}" ]
          }
        }, status: :unprocessable_entity
      end
      plans = plans.where(status: params[:status])
    end

    render json: plans.map { |plan| plan_summary(plan) }, status: :ok
  end

  def show
    plan = Current.user.plans.includes(:weeks).find(params[:id])
    render json: plan_detail(plan), status: :ok
  end

  private

  def plan_params
    params.require(:plan).permit(
      :baseline_vertical_distance,
      :baseline_duration,
      :goal_vertical_distance,
      :goal_duration,
      :recovery_pattern,
      :vertical_build_percentage,
      :flexible_end_date,
      :start_date,
      :end_date
    )
  end

  def plan_base(plan)
    plan.as_json(only: %i[
      id status recovery_pattern baseline_vertical_distance
      goal_vertical_distance vertical_build_percentage
      start_date end_date
    ])
  end

  def plan_summary(plan)
    plan_base(plan).merge(
      created_at: plan.created_at,
      week_count: plan.week_count,
      current_week_number: plan.current_week_number,
      progress_percentage: plan.progress_percentage
    )
  end

  def plan_detail(plan)
    plan_base(plan).merge(
      completed_date: plan.completed_date,
      weeks: plan.weeks.map { |week| week_detail(week) }
    )
  end

  def week_detail(week)
    week.as_json(only: %i[id week_number week_type status start_date end_date]).merge(
      days: week.days.map { |day| day_detail(day) }
    )
  end

  def day_detail(day)
    day.as_json(only: %i[id position planned_vertical_distance status])
  end
end
