class CreateCphcFacilityMappings < ActiveRecord::Migration[6.1]
  def change
    create_table :cphc_facility_mappings do |t|
      t.uuid :facility_id
      t.integer :cphc_state_id
      t.string :cphc_state_name
      t.integer :cphc_district_id
      t.string :cphc_district_name
      t.integer :cphc_taluka_id
      t.string :cphc_taluka_name
      t.integer :cphc_phc_id
      t.string :cphc_phc_name
      t.integer :cphc_subcenter_id
      t.string :cphc_subcenter_name
      t.integer :cphc_village_id
      t.string :cphc_village_name
      t.timestamp :deleted_at
      t.timestamps
    end
    add_index :cphc_facility_mappings, [
      :cphc_state_id,
      :cphc_state_name,
      :cphc_district_id,
      :cphc_district_name,
      :cphc_taluka_id,
      :cphc_taluka_name,
      :cphc_phc_id,
      :cphc_phc_name,
      :cphc_subcenter_id,
      :cphc_subcenter_name,
      :cphc_village_id,
      :cphc_village_name
    ], unique: true, name: :cphc_facility_mappings_unique_cphc_record
  end
end
