class Communication < ApplicationRecord
  include Mergeable

  belongs_to :appointment
  belongs_to :user
  belongs_to :detailable, polymorphic: true, optional: true

  enum communication_type: {
    manual_call: 'manual_call',
    voip_call: 'voip_call',
    reminder_sms: 'reminder_sms'
  }, _prefix: true

  enum communication_result: {
    unavailable: 'unavailable',
    unreachable: 'unreachable',
    successful: 'successful',
    unsuccessful: 'unsuccessful',
    in_progress: 'in_progress',
  }

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true

  scope :reminder_sms, -> { where(communication_type: :reminder_sms) }

  def self.create_with_twilio_details!(user:, appointment:, twilio_session_id:, twilio_msg_status:)
    transaction do
      sms_delivery_details =
        TwilioSmsDeliveryDetail.create!(session_id: twilio_session_id,
                                        result: twilio_msg_status,
                                        callee_phone_number: appointment.patient.latest_phone_number)
      Communication.create!(communication_type: :reminder_sms,
                            communication_result: :in_progress,
                            detailable: sms_delivery_details,

                            appointment: appointment,
                            user: user,

                            device_created_at: DateTime.now,
                            device_updated_at: DateTime.now)
    end
  end

  def days_since_scheduled_visit
    (device_created_at.to_date - appointment.scheduled_date).to_i
  end
end
