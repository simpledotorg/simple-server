class ExotelCallDetailsJob < ApplicationJob
  queue_as :default

  def perform(call_id, user_id, patient_phone_number_id)
    call_details = ExotelAPI.new(ENV['EXOTEL_SID'], ENV['EXOTEL_TOKEN']).call_details(call_id)

    if call_details.present?
      participant_details = { user: User.find(user_id),
                              patient_phone_number: PatientPhoneNumber.find(patient_phone_number_id) }

      call_log_params = parse_call_details(call_details).merge(participant_details)
      CallLog.create!(call_log_params)
    end
  end

  def parse_call_details(call_details)
    {
      session_id: call_details[:Sid],
      result: call_details[:Status],
      start_time: call_details[:StartTime],
      end_time: call_details[:EndTime],
      duration: call_details[:Duration]
    }
  end
end
