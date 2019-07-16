class AutomaticPhoneNumberWhitelistingJob < ApplicationJob
  queue_as :exotel_phone_whitelist

  self.queue_adapter = :sidekiq

  def perform
    patient_phone_numbers_for_whitelisting = PatientPhoneNumber.all.sele
  end
end
