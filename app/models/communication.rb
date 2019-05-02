class Communication < ApplicationRecord
  include Mergeable

  belongs_to :appointment
  belongs_to :user
  belongs_to :detailable, polymorphic: true

  delegate :unsuccessful?, :successful?, :in_progress?, to: detailable

  enum communication_type: {
    voip_call: 'voip_call',
    manual_call: 'manual_call',
    follow_up_reminder: 'follow_up_reminder'
  }

  COMMUNICATION_RESULTS = {
    unavailable: 'unavailable',
    unreachable: 'unreachable',
    successful: 'successful',
    unsuccessful: 'unsuccessful',
    in_progress: 'in_progress',
    unknown: 'unknown'
  }

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true

  def self.create_with_twilio_details!(user:, appointment:, twilio_sid:, twilio_msg_status:, communication_type:)
    transaction do
      sms_delivery_details =
        TwilioSmsDeliveryDetail.create!(session_id: twilio_sid,
                                        result: twilio_msg_status,
                                        callee_phone_number: appointment.patient.latest_phone_number)
      Communication.create!(communication_type: communication_type,
                            detailable: sms_delivery_details,
                            appointment: appointment,
                            user: user,
                            device_created_at: DateTime.now,
                            device_updated_at: DateTime.now)
    end
  end

  def communication_result
    case
    when successful? then
      COMMUNICATION_RESULTS[:successful]
    when unsuccessful? then
      COMMUNICATION_RESULTS[:unsuccessful]
    when in_progress? then
      COMMUNICATION_RESULTS[:in_progress]
    else
      COMMUNICATION_RESULTS[:unknown]
    end
  end
end
