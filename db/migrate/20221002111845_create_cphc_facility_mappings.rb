class CreateCphcFacilityMappings < ActiveRecord::Migration[6.1]
  def change
    create_table :cphc_facility_mappings do |t|
      t.uuid :facility_id
      t.string :cphc_state_id
      t.string :cphc_state_name
      t.string :cphc_district_id
      t.string :cphc_district_name
      t.string :cphc_taluka_id
      t.string :cphc_taluka_name
      t.string :cphc_phc_id
      t.string :cphc_phc_name
      t.string :cphc_subcenter_id
      t.string :cphc_subcenter_name
      t.string :cphc_village_id
      t.string :cphc_village_name
      t.timestamp :deleted_at
      t.timestamps
    end
  end
end
