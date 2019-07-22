class AutomaticPhoneNumberWhitelistingJob < ApplicationJob
  queue_as :phone_number_details_queue
  self.queue_adapter = :sidekiq

  def perform(virtual_number, sid, token, batch_size)
    PatientPhoneNumber.require_whitelisting.in_batches(of: batch_size) do |batch|
      numbers = batch.pluck(:number)
      ExotelAPIService.new(sid, token)
        .whitelist_phone_numbers(virtual_number, numbers)

      time = Time.now
      batch.each { |patient_phone_number| patient_phone_number.update_whitelist_requested_at(time) }
    end
  end
end
