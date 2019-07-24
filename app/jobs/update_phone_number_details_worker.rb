class UpdatePhoneNumberDetailsWorker
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker

  sidekiq_options queue: :phone_number_details_queue

  sidekiq_throttle(
    concurrency: { limit: 2 },
    threshold: { limit: 1, period: 30.seconds }
  )

  def perform(patient_phone_number_id, sid, token)
    patient_phone_number = PatientPhoneNumber.find(patient_phone_number_id)
    patient_phone_number.update_exotel_phone_number_detail(
      ExotelAPIService.new(sid, token)
        .get_phone_number_details(patient_phone_number.number)
    )
  end
end