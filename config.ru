# This file is used by Rack-based servers to start the application.

require_relative "config/environment"

if defined?(PhusionPassenger)
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    if forked
      require "prometheus_exporter/instrumentation"
      PrometheusExporter::Instrumentation::Process.start(type: "web")
    end
  end
end

run Rails.application
