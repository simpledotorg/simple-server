class AddFacilityShortName < ActiveRecord::Migration[5.2]
  def change
    add_column :facilities, :short_name, :string
  end
end
