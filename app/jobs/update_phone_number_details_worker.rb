# frozen_string_literal: true

class UpdatePhoneNumberDetailsWorker
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker

  sidekiq_options queue: :low
  sidekiq_options retry: 5

  sidekiq_throttle(
    threshold: {limit: ENV["EXOTEL_API_RATE_LIMIT_PER_MINUTE"].to_i || 250, period: 1.minute}
  )

  def logger
    @logger ||= Notification.logger(class: self.class.name)
  end

  def perform(patient_phone_number_id, sid, token)
    patient_phone_number = PatientPhoneNumber.find(patient_phone_number_id)
    if patient_phone_number.invalid?
      errors = patient_phone_number.errors
      logger.warn(msg: "Patient phone number #{patient_phone_number_id} is invalid, skipping phone number update", errors: errors)
      return
    end
    patient_phone_number.update_exotel_phone_number_detail(
      ExotelAPIService.new(sid, token)
        .phone_number_details(patient_phone_number.number)
    )
  end
end
