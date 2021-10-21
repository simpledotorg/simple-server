module Experimentation
  class StalePatientExperiment < NotificationsExperiment
    default_scope { where(experiment_type: %w[stale_patients]) }

    def self.candidate_patients(date)
      # TODO: change this to accept a time,
      # it is used to determine if patients have an appointment in the "future"
      StalePatientSelection.call(start_time: date)
    end
  end
end
