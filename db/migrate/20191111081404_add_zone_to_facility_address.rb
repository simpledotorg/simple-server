class AddZoneToFacilityAddress < ActiveRecord::Migration[5.1]
  def change
    add_column :facilities, :zone, :string, null: true
  end
end
