class AddLatLongToFacilities < ActiveRecord::Migration[5.1]
  def change
    add_column :facilities, :latitude, :decimal, precision: 10, scale: 6
    add_column :facilities, :longitude, :decimal, precision: 10, scale: 6
  end
end
