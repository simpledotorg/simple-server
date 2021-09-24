Sentry.init do |config|
  config.async = lambda do |event, hint|
    Sentry::SendEventJob.perform_later(event, hint)
  end
end
