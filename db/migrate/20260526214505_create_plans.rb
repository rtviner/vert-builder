class CreatePlans < ActiveRecord::Migration[8.1]
  def change
    create_table :plans do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :baseline_vertical_distance, null: false, default: 0
      t.integer :baseline_duration, null: false, default: 0
      t.integer :goal_vertical_distance, null: false, default: 0
      t.integer :goal_duration, null: true, default: 0
      t.date :start_date, null: true
      t.date :end_date, null: true
      t.date :completed_date, null: true
      t.boolean :flexible_end_date, null: false, default: false
      t.integer :recovery_pattern, null: false
      t.integer :vertical_build_percentage, null: false, default: 10
      t.integer :status, null: false, default: 0

      t.timestamps
    end
  end
end
