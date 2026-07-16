class UpdatePlansGoalColumns < ActiveRecord::Migration[8.1]
  def change
    change_column_null :plans, :goal_vertical_distance, false
    change_column_default :plans, :goal_vertical_distance, from: 0, to: nil
    change_column_null :plans, :goal_duration, true
    change_column_default :plans, :goal_duration, from: 0, to: nil
  end
end
