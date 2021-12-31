module Reports
  class AppointmentScheduledDaysDistribution < Reports::View
    self.table_name = "reporting_appointment_scheduled_days_distributions"
    belongs_to :facility

    def self.materialized?
      true
    end
  end
end
