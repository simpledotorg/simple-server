module Experimentation
  class RunnerV2
    def self.call
      unless Flipper.enabled?(:experiment)
        logger.info("Experiment feature flag is off. Experiments #{name} will not be started.")
        return
      end

      experiments = [Experimentation::CurrentPatientExperiment, Experimentation::StalePatientExperiment]

      experiments.flat_map(&:running).each { |experiment| experiment.enroll_patients(Date.current) }
      experiments.flat_map(&:monitoring).each { |experiment| experiment.monitor(Date.current) }
      experiments.flat_map(&:notifying).each { |experiment| experiment.send_notifications(Date.current) }
    end
  end
end
