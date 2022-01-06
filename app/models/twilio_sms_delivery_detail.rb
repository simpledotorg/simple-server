# frozen_string_literal: true

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
end
