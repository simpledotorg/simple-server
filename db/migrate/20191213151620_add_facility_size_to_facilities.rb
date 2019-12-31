class AddFacilitySizeToFacilities < ActiveRecord::Migration[5.1]
  def change
    add_column :facilities, :facility_size, :string
  end
end
