module Experimentation
  class CurrentPatientSelection
    def self.call(start_date:, end_date:)
      Experiment.candidate_patients
        .joins(:appointments)
        .merge(Appointment.status_scheduled)
        .where("appointments.scheduled_date BETWEEN ? and ?", start_date, end_date)
        .distinct
        .pluck(:id)
    end
  end
end
