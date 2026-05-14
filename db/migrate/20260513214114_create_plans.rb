class CreatePlans < ActiveRecord::Migration[8.1]
  def change
    create_table :plans do |t|
      t.references :user, null: false, foreign_key: true
      t.date :start_date

      t.timestamps
    end
  end
end
