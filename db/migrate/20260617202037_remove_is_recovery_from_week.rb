class RemoveIsRecoveryFromWeek < ActiveRecord::Migration[8.1]
  def change
    remove_column :weeks, :is_recovery, :boolean
  end
end
