class AddIndexesToReportingPatientStates < ActiveRecord::Migration[6.1]
  # Cannot create index concurrently inside a transaction block
  self.disable_ddl_transaction = true

  def change
    add_index :reporting_patient_states, %i[month_date assigned_facility_id], name: "patient_states_month_date_assigned_facility", algorithm: :concurrently
    add_index :reporting_patient_states, %i[month_date assigned_facility_region_id], name: "patient_states_month_date_assigned_facility_region", algorithm: :concurrently
    add_index :reporting_patient_states, %i[month_date registration_facility_id], name: "patient_states_month_date_registration_facility", algorithm: :concurrently
    add_index :reporting_patient_states, %i[month_date registration_facility_region_id], name: "patient_states_month_date_registration_facility_region", algorithm: :concurrently
  end
end
