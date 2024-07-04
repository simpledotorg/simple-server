Sentry.init do |config|
  config.sample_rate = ENV.fetch("SENTRY_SAMPLE_RATE", 1.0).to_f
end
