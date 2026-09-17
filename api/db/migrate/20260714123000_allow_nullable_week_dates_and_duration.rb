class AllowNullableWeekDatesAndDuration < ActiveRecord::Migration[8.1]
  def change
    change_column_null :weeks, :start_date, true
    change_column_null :weeks, :end_date, true
    change_column_null :weeks, :planned_duration, true
    change_column_default :weeks, :planned_duration, nil
  end
end
