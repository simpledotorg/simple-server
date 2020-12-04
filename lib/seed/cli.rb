require "parallel"

module Seed
  class Cli
    SUCCESS_STATUS_CODE = 0
    FAILURE_STATUS_CODE = 1

    def initialize(argv, output: $stdout, input: $stdin)
      @argv = argv
      @output = output
      @input = input
    end

    attr_reader :input
    attr_reader :output
    attr_reader :processor_count

    def run
      config = Seed::Config.new
      output.puts "Starting seed process with a *#{config.type}* sized data set using #{Parallel::processor_count} cores, continue? (Y/n)"
      answer = input.gets.chomp
      if answer == "Y"
        Seed::Runner.call
      else
        output.puts "Aborting..."
      end
      SUCCESS_STATUS_CODE
    end
  end
end
