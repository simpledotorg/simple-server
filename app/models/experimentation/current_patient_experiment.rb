module Experimentation
  class CurrentPatientExperiment < NotificationsExperiment
    default_scope { where(experiment_type: %w[current_patients]) }

    def self.eligible_patients(date)
      super.eligible_patients
        .joins(:appointments)
        .merge(Appointment.status_scheduled)
        .where("appointments.scheduled_date BETWEEN ? and ?", date.beginning_of_day, date.end_of_day)
        .distinct
    end
  end
end
