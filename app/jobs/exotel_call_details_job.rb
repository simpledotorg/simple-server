class ExotelCallDetailsJob < ApplicationJob
  queue_as :default

  retry_on ExotelAPI::HTTPError,
           wait: 5.seconds, attempts: 5

  def perform(call_id, user_id, callee_phone_number)
    call_details = ExotelAPI.new(ENV['EXOTEL_SID'],
                                 ENV['EXOTEL_TOKEN']).call_details(call_id)

    CallLog.create!(call_log_params(call_details,
                                    user_id,
                                    callee_phone_number)) if call_details.present?
  end

  def participant_details(user_id, callee_phone_number)
    { user_id: user_id,
      callee_phone_number: callee_phone_number }
  end

  def parse_call_details(call_details)
    { session_id: call_details.Sid,
      end_time: call_details.EndTime,
      start_time: call_details.StartTime,
      result: call_details.Status,
      duration: call_details.Duration }
  end

  def call_log_params(call_details, user_id, callee_phone_number)
    parse_call_details(call_details)
      .merge(participant_details(user_id, callee_phone_number))
  end
end
