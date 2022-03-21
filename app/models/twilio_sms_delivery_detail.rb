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

  def self.create_with_communication(callee_phone_number:, communication_type:, session_id:, result:)
    ActiveRecord::Base.transaction do
      delivery_detail = create!(
        session_id: session_id,
        result: result,
        callee_phone_number: callee_phone_number
      )

      Communication.create!(
        communication_type: communication_type,
        detailable: delivery_detail
      )
    end
  end
end
