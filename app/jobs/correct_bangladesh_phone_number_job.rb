class CorrectBangladeshPhoneNumberJob < ApplicationJob
  queue_as :default
  self.queue_adapter = :sidekiq

  def perform(patient)
    CorrectBangladeshPhoneNumber.perform(patient)
  end
end
