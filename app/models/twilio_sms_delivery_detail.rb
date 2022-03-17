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

  def record_communication(response:, recipient_number:, communication_type:)
    ActiveRecord::Base.transaction do
      delivery_detail = create!(
        session_id: response.sid,
        result: response.status,
        callee_phone_number: recipient_number
      )

      Communication.create!(
        communication_type: communication_type,
        detailable: delivery_detail
      )
    end
  end
end
