class AddSoftDeletesToOrganizationsAndFacilityGroups < ActiveRecord::Migration[5.1]
  def change
    add_column :organizations, :deleted_at, :datetime
    add_index :organizations, :deleted_at

    add_column :facility_groups, :deleted_at, :datetime
    add_index :facility_groups, :deleted_at
  end
end
