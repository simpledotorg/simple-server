class SentryJob < ActiveJob::Base
  queue_as :default

  def perform(event, hint)
    Sentry.send_event(event, hint)
  end
end

Sentry.init do |config|
  config.async = ->(event, hint) { SentryJob.perform_later(event, hint) }
end
