class ApplicationJob < ActiveJob::Base
  self.queue_adapter = :sidekiq
end
