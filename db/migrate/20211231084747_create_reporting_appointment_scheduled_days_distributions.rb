class CreateReportingAppointmentScheduledDaysDistributions < ActiveRecord::Migration[5.2]
  def change
    create_view :reporting_appointment_scheduled_days_distributions
  end
end
