class AutomaticPhoneNumberWhitelistingJob < ApplicationJob
  queue_as :exotel_phone_whitelist

  self.queue_adapter = :sidekiq

  def perform
    # Get all phone numbers which need whitelisting
    # ie: DND_status is true, and whitelist_status is either 'neutral' or unknown
    patient_phone_numbers_for_whitelisting = PatientPhoneNumber.includes(:exotel_phone_number_details)
  end
end
