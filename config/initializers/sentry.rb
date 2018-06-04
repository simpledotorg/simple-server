class SentryJob < ActiveJob::Base
  queue_as :default

  def perform(event)
    Raven.send_event(event)
  end
end

Raven.configure do |config|
  config.environments = %w[staging production]
  config.sanitize_fields = Rails.application.config.filter_parameters.map(&:to_s)
  config.async = ->(event) { SentryJob.perform_later(event) }
end
