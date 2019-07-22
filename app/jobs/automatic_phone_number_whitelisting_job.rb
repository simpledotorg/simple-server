class AutomaticPhoneNumberWhitelistingJob
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker

  sidekiq_options queue: :phone_number_details_queue

  sidekiq_throttle(
    concurrency: { limit: 2 },
    threshold: { limit: 1, period: 30.seconds } 
  )

  def perform(patient_phone_number_ids, virtual_number, sid, token)
    patient_phone_numbers = PatientPhoneNumber.where(id: patient_phone_number_ids).includes(:exotel_phone_number_detail)
    numbers = patient_phone_numbers.pluck(:number)
    ExotelAPIService.new(sid, token)
      .whitelist_phone_numbers(virtual_number, numbers)

    time = Time.now
    patient_phone_numbers.each { |patient_phone_number| patient_phone_number.update_whitelist_requested_at(time) }
  end
end