class CreateReportingPatientFollowUps < ActiveRecord::Migration[5.2]
  def change
    create_view :reporting_patient_follow_ups, materialized: true
  end
end
