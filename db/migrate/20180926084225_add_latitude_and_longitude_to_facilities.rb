class AddLatitudeAndLongitudeToFacilities < ActiveRecord::Migration[5.1]
  def change
    change_table :facilities do |t|
      t.float :latitude, null: true
      t.float :longitude, null: true
    end
  end
end
