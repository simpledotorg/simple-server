module Reports
  class Experiment
    include Scientist
    attr_accessor :name

    def initialize(name)
      @name = name
    end

    def enabled?
      # see "Ramping up experiments" below
      true
    end

    def raised(operation, error)
      # see "In a Scientist callback" below
      p "Operation '#{operation}' failed with error '#{error.inspect}'"
      super # will re-raise
    end

    def publish(result)
      # see "Publishing results" below
      p result
    end
  end
  Experiment.raise_on_mismatches = true
end


