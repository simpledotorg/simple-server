class AddIndexToZone < ActiveRecord::Migration[5.2]
  def change
    add_index :facilities, :zone
  end
end
