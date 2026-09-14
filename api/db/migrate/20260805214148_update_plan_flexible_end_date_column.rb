class UpdatePlanFlexibleEndDateColumn < ActiveRecord::Migration[8.1]
  def change
    change_column_default :plans, :flexible_end_date, from: false, to: true
  end
end
