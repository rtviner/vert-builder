class CreateWeeks < ActiveRecord::Migration[8.1]
  def change
    create_table :weeks do |t|
      t.references :plan, null: false, foreign_key: true
      t.integer :week_number, null: false
      t.boolean :is_recovery, null: false, default: false
      t.integer :status, null: false, default: 0
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.integer :planned_duration, null: false, default: 0
      t.integer :completed_duration, null: false, default: 0
      t.integer :planned_vertical_distance, null: false, default: 0
      t.integer :completed_vertical_distance, null: false, default: 0

      t.timestamps
    end
    add_index :weeks, [:plan_id, :week_number], unique: true
  end
end
