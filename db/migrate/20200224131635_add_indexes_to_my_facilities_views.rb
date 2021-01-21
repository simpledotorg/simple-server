class AddIndexesToMyFacilitiesViews < ActiveRecord::Migration[5.1]
  def change
    add_index :blood_pressures_per_facility_per_days, [:facility_id, :day, :year], unique: true,
                                                                                   name: "index_blood_pressures_per_facility_per_days"
    add_index :latest_blood_pressures_per_patient_per_months, :bp_id, unique: true,
                                                                      name: "index_latest_blood_pressures_per_patient_per_months"
    add_index :latest_blood_pressures_per_patient_per_quarters, :bp_id, unique: true,
                                                                        name: "index_latest_blood_pressures_per_patient_per_quarters"
    add_index :latest_blood_pressures_per_patients, :bp_id, unique: true,
                                                            name: "index_latest_blood_pressures_per_patients"
    add_index :patient_registrations_per_day_per_facilities, [:facility_id, :day, :year], unique: true,
                                                                                          name: "index_patient_registrations_per_day_per_facilities"
  end
end
