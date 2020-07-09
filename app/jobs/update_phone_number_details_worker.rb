class UpdatePhoneNumberDetailsWorker
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker

  sidekiq_options queue: :phone_number_details_queue

  sidekiq_throttle(
    threshold: {limit: ENV["EXOTEL_API_RATE_LIMIT_PER_MINUTE"].to_i || 250, period: 1.minute}
  )

  def perform(patient_phone_number_id, sid, token)
    patient_phone_number = PatientPhoneNumber.find(patient_phone_number_id)
    patient_phone_number.update_exotel_phone_number_detail(
      ExotelAPIService.new(sid, token)
        .phone_number_details(patient_phone_number.number)
    )
  end
end
