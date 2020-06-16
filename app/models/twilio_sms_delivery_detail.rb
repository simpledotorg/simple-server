class TwilioSmsDeliveryDetail < ApplicationRecord
  has_one :communication, as: :detailable

  enum result: {
    queued: "queued",
    failed: "failed",
    sent: "sent",
    delivered: "delivered",
    undelivered: "undelivered",
    unknown: "unknown"
  }

  def unsuccessful?
    failed? || undelivered? || unknown?
  end

  def successful?
    delivered?
  end

  def in_progress?
    queued? || sent?
  end
end
