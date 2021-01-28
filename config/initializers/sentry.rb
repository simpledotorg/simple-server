class SentryJob < ActiveJob::Base
  queue_as :default

  def perform(event)
    Sentry.send_event(event)
  end
end

Sentry.init do |config|
  config.sanitize_fields = Rails.application.config.filter_parameters.map(&:to_s)
  config.async = ->(event) { SentryJob.perform_later(event) }
end
