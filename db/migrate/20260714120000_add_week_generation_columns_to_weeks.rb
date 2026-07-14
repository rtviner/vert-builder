class AddWeekGenerationColumnsToWeeks < ActiveRecord::Migration[8.1]
  def change
    add_column :weeks, :recovery_reduction_percentage, :integer, null: true, default: nil
    add_column :weeks, :vertical_build_percentage, :integer, null: true, default: nil
  end
end
