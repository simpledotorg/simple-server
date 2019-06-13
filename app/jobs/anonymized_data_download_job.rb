class AnonymizedDataDownloadJob < ApplicationJob
  queue_as :default
  self.queue_adapter = :sidekiq

  DEFAULT_RETRY_TIMES = 2
  DEFAULT_RETRY_SECONDS = 5.minutes.seconds.to_i

  def perform(*args)
    status = AnonymizedDataDownloadService.new.execute
    puts "Status - #{status}"
  end
end
