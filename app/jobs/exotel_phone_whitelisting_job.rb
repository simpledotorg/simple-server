class ExotelPhoneWhitelistingJob < ApplicationJob
  queue_as :exotel_phone_whitelist

  self.queue_adapter = :sidekiq

  def perform

  end
end
