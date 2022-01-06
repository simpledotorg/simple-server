# frozen_string_literal: true

module Reports
  class Experiment
    include Scientist::Experiment
    attr_accessor :name

    def initialize(name)
      @name = name
    end

    def enabled?
      SimpleServer.env.development? || SimpleServer.env.sandbox? || SimpleServer.env.test?
    end

    def raised(operation, error)
      p "Operation '#{operation}' failed with error '#{error.inspect}'"
    end

    def publish(result)
    end
  end
  Experiment.raise_on_mismatches = ENV["RAISE_ON_MISMATCH"]
end
