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
end
