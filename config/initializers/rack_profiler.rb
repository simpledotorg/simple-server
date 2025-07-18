if ENV["RACK_MINI_PROFILER"]
  Rails.logger.info "Initializing rack-mini-profiler"
  require "stackprof"
  require "memory_profiler"
  require "rack-mini-profiler"

  # initialization is skipped so we do it manually
  Rack::MiniProfilerRails.initialize!(Rails.application)
  Rack::MiniProfiler.config.enable_advanced_debugging_tools = true
  Rack::MiniProfiler.config.skip_paths = [%r{/webview/}, %r{/api}]
  if Rails.env.profiling? # we want to disable any authorization for the profiling env, as this would only be run locally
    Rack::MiniProfiler.config.authorization_mode = :allow_all
  end
end
