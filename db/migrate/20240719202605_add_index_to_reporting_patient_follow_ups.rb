class AddIndexToReportingPatientFollowUps < ActiveRecord::Migration[6.1]
  def change
    add_index :reporting_patient_follow_ups, :facility_id
  end
end
