class TwilioSmsDeliveryDetail < ApplicationRecord
  has_one :communication, as: :detailable

  enum result: {
    queued: "queued",
    sending: "sending",
    sent: "sent",
    delivered: "delivered",
    undelivered: "undelivered",
    failed: "failed",
    read: "read",
    unknown: "unknown"
  }

  def unsuccessful?
    failed? || undelivered? || unknown?
  end

  def successful?
    delivered? || read?
  end

  def in_progress?
    queued? || sending? || sent?
  end

  def create_with_communication(response:, notification:, communication_type:, recipient_number:)
    now = DateTime.current
    transaction do
      sms_delivery_details = TwilioSmsDeliveryDetail.create!(session_id: twilio_sid,
                                                             result: twilio_msg_status,
                                                             callee_phone_number: recipient_number)
      create!(communication_type: communication_type, detailable: sms_delivery_details, notification: notification)
    end
  end
end
