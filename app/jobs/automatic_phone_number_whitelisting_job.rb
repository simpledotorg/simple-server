class AutomaticPhoneNumberWhitelistingJob < ApplicationJob
  queue_as :phone_number_details_queue
  self.queue_adapter = :sidekiq

  def perform(virtual_number, sid, token, delay: 1, batch_size: 10000)
    PatientPhoneNumber.require_whitelisting.in_batches(of: batch_size) do |batch|
      numbers = batch.pluck(:number)
      ExotelAPIService.new(sid, token)
        .whitelist_phone_numbers(virtual_number, numbers)


      sleep(delay)
    end
  end
end
