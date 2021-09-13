# frozen_string_literal: true

if Rails.env.development? && !ENV["PROFILE"]
  require "rack-mini-profiler"

  # initialization is skipped so trigger it
  Rack::MiniProfilerRails.initialize!(Rails.application)
  Rack::MiniProfiler.config.skip_paths = [%r{/webview/}, %r{/api}]
end
