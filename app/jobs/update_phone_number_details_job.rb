class UpdatePhoneNumberDetailsJob < ApplicationJob
  queue_as :phone_number_details_queue
  self.queue_adapter = :sidekiq

  def perform(patient_phone_number_id, sid, token)
    patient_phone_number = PatientPhoneNumber.find(patient_phone_number_id)
    patient_phone_number.update_exotel_phone_number_detail(
      ExotelAPIService.new(sid, token)
        .get_phone_number_details(patient_phone_number.number)
    )
  end
end