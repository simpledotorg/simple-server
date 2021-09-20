# Only use mini profiler in dev if we _don't_ have datadog turned on
if Rails.env.development? && !ENV["DATADOG_ENABLED"]
  require "rack-mini-profiler"

  # initialization is skipped so trigger it
  Rack::MiniProfilerRails.initialize!(Rails.application)
  Rack::MiniProfiler.config.skip_paths = [%r{/webview/}, %r{/api}]
end
