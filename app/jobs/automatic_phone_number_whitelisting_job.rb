class AutomaticPhoneNumberWhitelistingJob < ApplicationJob
  queue_as :exotel_phone_whitelist
  self.queue_adapter = :sidekiq

  BATCH_SIZE = (ENV.fetch('BATCH_SIZE') || 1000).to_i
  EXOTEL_VIRTUAL_NUMBER = ENV.fetch('EXOTEL_VIRTUAL_PHONE_NUMBER')

  # TODO: Add EXOTEL_VIRTUAL_NUMBER and BATCH SIZE to env files

  def perform
    PatientPhoneNumber.require_whitelisting.in_batches(of: BATCH_SIZE) do |batch|
      numbers = batch.pluck(:numbers).join(',')
      ExotelAPIService.new(ENV['EXOTEL_SID'],
                           ENV['EXOTEL_TOKEN'])
        .whitelist_phone_numbers(EXOTEL_VIRTUAL_NUMBER, numbers)

      sleep(1)
    end
  end
end
