module Experimentation
  class RunnerV2
    def self.call
      unless Flipper.enabled?(:experiment)
        logger.info("Experiment feature flag is off. Experiments #{name} will not be started.")
        return
      end

      Experimentation::Experiment.running.each { |experiment| experiment.klass.new(experiment, Date.current).enroll_patients }
      Experimentation::Experiment.monitoring.each { |experiment| experiment.klass.new(experiment, Date.current).monitor }
    end
  end
end
