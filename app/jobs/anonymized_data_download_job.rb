class AnonymizedDataDownloadJob < ApplicationJob
  queue_as :default
  self.queue_adapter = :sidekiq

  DEFAULT_RETRY_TIMES = 3
  DEFAULT_RETRY_SECONDS = 5.minutes.seconds.to_i

  def perform(recipient_name, recipient_email, entity_map, entity_type)
    AnonymizedDataDownloadService.new(recipient_name, recipient_email, entity_map, entity_type).execute
  end
end
