class Messaging::VoiceAgent::Call < Messaging::Channel
  def self.communication_type
    Communication.communication_types[:ai_voice_call]
  end

  # Unlike SMS, the call happens asynchronously. The voice agent accepts the request here
  # and reports the outcome later to Api::V4::VoiceCallOutcomesController.
  def send_message(notification:, &with_communication_do)
    track_metrics do
      call_request = ::VoiceAgent::CallRequest.new(notification)
      Messaging::VoiceAgent::Api.new.create_call(call_request.payload)
      create_communication(call_request.call_request_id, &with_communication_do)
    end
  end

  private

  def create_communication(call_request_id, &with_communication_do)
    ActiveRecord::Base.transaction do
      VoiceCallDetail.create_with_communication!(call_request_id: call_request_id).tap do |communication|
        with_communication_do&.call(communication)
      end
    end
  end
end
