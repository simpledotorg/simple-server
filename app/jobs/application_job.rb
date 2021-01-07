class ApplicationJob < ActiveJob::Base
  queue_as :default
  self.queue_adapter = :sidekiq
end
