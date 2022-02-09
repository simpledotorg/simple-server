class CreateReportingFacilityAppointmentScheduledDays < ActiveRecord::Migration[5.2]
  def change
    create_view :reporting_facility_appointment_scheduled_days, materialized: true

    add_index :reporting_facility_appointment_scheduled_days, [:month_date, :facility_id], unique: true, name: :index_reporting_facility_appointment_scheduled_days
  end
end
