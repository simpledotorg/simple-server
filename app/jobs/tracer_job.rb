class TracerJob < ApplicationJob
  queue_as :default
  self.queue_adapter = :sidekiq

  def perform(submitted_at)
    Rails.logger.info msg: "tracer job completed successfully, was submitted at #{submitted_at}",
                      submitted_at: submitted_at
  end
end
