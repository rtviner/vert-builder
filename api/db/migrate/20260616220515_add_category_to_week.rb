class AddCategoryToWeek < ActiveRecord::Migration[8.1]
  def change
    add_column :weeks, :category, :string
  end
end
