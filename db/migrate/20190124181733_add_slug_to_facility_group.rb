class AddSlugToFacilityGroup < ActiveRecord::Migration[5.1]
  def change
    add_column :facility_groups, :slug, :string
    add_index :facility_groups, :slug, unique: true
  end
end
