module Reports
  class FacilityAppointmentScheduledDays < Reports::View
    self.table_name = "reporting_facility_appointment_scheduled_days"
    belongs_to :facility

    def self.materialized?
      true
    end
  end
end
