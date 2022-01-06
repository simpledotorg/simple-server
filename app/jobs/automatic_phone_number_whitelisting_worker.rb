# frozen_string_literal: true

class AutomaticPhoneNumberWhitelistingWorker
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker

  sidekiq_options queue: :low

  sidekiq_throttle(
    threshold: {limit: ENV["EXOTEL_API_RATE_LIMIT_PER_MINUTE"].to_i || 250, period: 1.minute}
  )

  def perform(patient_phone_number_ids, virtual_number, sid, token)
    patient_phone_numbers = PatientPhoneNumber.where(id: patient_phone_number_ids).includes(:exotel_phone_number_detail)
    numbers = patient_phone_numbers.pluck(:number)
    ExotelAPIService.new(sid, token)
      .whitelist_phone_numbers(virtual_number, numbers)

    time = Time.current
    patient_phone_numbers.each { |patient_phone_number| patient_phone_number.update_whitelist_requested_at(time) }
  end
end
