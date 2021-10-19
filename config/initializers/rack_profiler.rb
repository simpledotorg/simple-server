# Only use mini profiler if we _don't_ have Datadog turned on
if ENV["RACK_MINI_PROFILER"] && !ENV["DATADOG_ENABLED"]
  Rails.logger.info "Initializing rack-mini-profiler"
  require "stackprof"
  require "rack-mini-profiler"

  # initialization is skipped so we do it manually
  Rack::MiniProfilerRails.initialize!(Rails.application)
  Rack::MiniProfiler.config.skip_paths = [%r{/webview/}, %r{/api}]
  if Rails.env.profiling? # we want to disable any authorization for the profiling env, as this would only be run locally
    Rack::MiniProfiler.config.authorization_mode = :allow_all
  end
end
