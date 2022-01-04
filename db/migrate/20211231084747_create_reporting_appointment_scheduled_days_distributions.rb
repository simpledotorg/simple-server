class CreateReportingAppointmentScheduledDaysDistributions < ActiveRecord::Migration[5.2]
  def change
    create_view :reporting_appointment_scheduled_days_distributions, materialized: true

    add_index :reporting_appointment_scheduled_days_distributions, [:month_date, :facility_id], unique: true, name: :index_reporting_appointment_scheduled_days_distributions
  end
end
