class DropFacilityStateField < ActiveRecord::Migration[5.2]
  def change
    remove_column :facilities, :state
  end
end
