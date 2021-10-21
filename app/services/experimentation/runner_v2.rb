module Experimentation
  class RunnerV2
    def self.call
      unless Flipper.enabled?(:experiment)
        logger.info("Experiment feature flag is off. Experiments #{name} will not be started.")
        return
      end

      experiments = [Experimentation::CurrentPatientExperiment, Experimentation::StalePatientExperiment]

      experiments.each(&:running).each { |experiment| experiment.enroll_patients(Date.current) }
      experiments.each(&:monitoring).each { |experiment| experiment.monitor(Date.current) }
      experiments.each(&:notifying).each { |experiment| experiment.send_notifications(Date.current) }
    end
  end
end
