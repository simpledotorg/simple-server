class CreateReportingPrescriptions < ActiveRecord::Migration[5.2]
  def up
    execute "SET LOCAL TIME ZONE '#{Rails.application.config.country[:time_zone]}'"
    create_view :reporting_prescriptions, version: 1, materialized: true
    add_index :reporting_prescriptions, [:patient_id, :month_date], unique: true, name: "reporting_prescriptions_patient_month_date"
  end

  def down
    drop_view :reporting_prescriptions, materialized: true
  end
end
