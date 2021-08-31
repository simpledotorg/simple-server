class CreateReportingPatientFollowUps < ActiveRecord::Migration[5.2]
  def change
    create_view :reporting_patient_follow_ups, materialized: true

    add_index :reporting_patient_follow_ups, [:patient_id, :user_id, :facility_id, :month_date], unique: true, name: "reporting_patient_follow_ups_unique_index"
  end
end
