# This file is used by Rack-based servers to start the application.

require_relative "config/environment"

if defined?(PhusionPassenger)
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    if forked
      Statsd.instance.reset!
    else
      # We're in direct spawning mode. We don't need to do anything.
    end
  end
end

run Rails.application
