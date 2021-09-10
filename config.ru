# This file is used by Rack-based servers to start the application.

require_relative "config/environment"

if ENABLE_DD_PROFILING
  require "ddtrace/profiling/preload"
end

if defined?(PhusionPassenger)
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    if forked
      Statsd.instance.reset!
    end
  end
end

run Rails.application
