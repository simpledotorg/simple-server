class AddLocationDetailsToCphcFacilities < ActiveRecord::Migration[6.1]
  def change
    add_column :cphc_facilities, :cphc_location_details, :json, null: true
  end
end
