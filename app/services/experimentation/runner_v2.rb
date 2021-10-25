module Experimentation
  class RunnerV2
    def self.call
      unless Flipper.enabled?(:experiment)
        Rails.logger.info("Experiment feature flag is off. Experiments #{name} will not be started.")
        return
      end

      [CurrentPatientExperiment, StalePatientExperiment].each { |experiment| experiment.daily_run(Date.current) }
    end
  end
end
