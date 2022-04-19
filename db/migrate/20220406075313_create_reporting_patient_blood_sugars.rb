class CreateReportingPatientBloodSugars < ActiveRecord::Migration[5.2]
  def change
    create_view :reporting_patient_blood_sugars, materialized: true
    add_index :reporting_patient_blood_sugars, [:month_date, :patient_id],
      unique: true,
      name: "patient_blood_sugars_month_date_patient_id"
  end
end
