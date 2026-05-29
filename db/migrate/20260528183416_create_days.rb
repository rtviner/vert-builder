class CreateDays < ActiveRecord::Migration[8.1]
  def change
    create_table :days do |t|
      t.references :week, null: false, foreign_key: true
      t.integer :planned_vertical_distance, null: false, default: 0
      t.integer :completed_vertical_distance, null: true, default: 0
      t.date :completed_date, null: true
      t.string :strava_activity_id, null: true
      t.integer :status, null: false, default: 0

      t.timestamps
    end
  end
end
