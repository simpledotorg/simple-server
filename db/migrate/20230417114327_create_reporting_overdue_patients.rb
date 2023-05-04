class CreateReportingOverduePatients < ActiveRecord::Migration[6.1]
  def change
    create_view :reporting_overdue_patients, materialized: true
    add_index :reporting_overdue_patients, [:month_date, :patient_id],
      unique: true,
      name: "overdue_patients_month_date_patient_id"
    add_index :reporting_overdue_patients, [:month_date, :assigned_facility_region_id],
      name: "overdue_patients_month_date_assigned_facility_region_id"
  end
end
