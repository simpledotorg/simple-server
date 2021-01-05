class TracerJob < ApplicationJob
  queue_as :default
  self.queue_adapter = :sidekiq

  def perform(submitted_at)
    Rails.logger.info class: self.class.name,
                      msg: "tracer job completed successfully, was submitted at #{submitted_at}",
                      submitted_at: submitted_at
  end
end
