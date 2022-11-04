class CreateCphcFacilityAndVillage < ActiveRecord::Migration[6.1]
  def change
    create_table :cphc_facilities, id: :uuid do |t|
      t.uuid :facility_id
      t.string :cphc_facility_id
      t.string :cphc_facility_name
      t.integer :cphc_district_id
      t.string :cphc_district_name
      t.integer :cphc_taluka_id
      t.string :cphc_taluka_name
      t.string :cphc_state_name
      t.integer :cphc_state_id
      t.string :cphc_facility_type # PHC OR subcenter
      t.string :cphc_facility_type_id

      t.timestamp :deleted_at
      t.timestamps
    end

    create_table :cphc_facility_villages, id: :uuid do |t|
      t.uuid :cphc_facility_id
      t.string :cphc_village_name
      t.string :cphc_village_id

      t.timestamp :deleted_at
      t.timestamps
    end
  end
end
