class CreateReportingPatientBloodSugars < ActiveRecord::Migration[5.2]
  def change
    create_view :reporting_patient_blood_sugars, materialized: true
  end
end
