class AddIndexesToReportingPatientStates < ActiveRecord::Migration[6.1]
  def change
    add_index :reporting_patient_states, %i[month_date assigned_facility_id], name: "patient_states_month_date_assigned_facility"
    add_index :reporting_patient_states, %i[month_date assigned_facility_region_id], name: "patient_states_month_date_assigned_facility_region"
  end
end
