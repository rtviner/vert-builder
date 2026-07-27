class Api::V1::PlansController < ApplicationController
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

  def plan_summary(plan)
    plan.as_json(only: %i[
      id status recovery_pattern baseline_vertical_distance
      goal_vertical_distance vertical_build_percentage
      start_date end_date created_at
    ]).merge(
      week_count: plan.week_count,
      current_week_number: plan.current_week_number,
      progress_percentage: plan.progress_percentage
    )
  end
end
