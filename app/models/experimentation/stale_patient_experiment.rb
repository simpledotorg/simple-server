module Experimentation
  class StalePatientExperiment < NotificationsExperiment
    default_scope { where(experiment_type: %w[stale_patients]) }

    def self.candidate_patients(date)
      StalePatientSelection.call(date: date)
    end
  end
end
