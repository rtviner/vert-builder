class AddPositionToDays < ActiveRecord::Migration[8.1]
  def change
    add_column :days, :position, :integer
  end
end
