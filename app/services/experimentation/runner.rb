module Experimentation
  class Runner
    def self.call
      unless Flipper.enabled?(:experiment)
        Rails.logger.info("Experiment feature flag is off. Experiments #{name} will not be started.")
        return
      end

      [CurrentPatientExperiment, StalePatientExperiment].each { |experiment| experiment.conduct_daily(Date.current) }
    end
  end
end
