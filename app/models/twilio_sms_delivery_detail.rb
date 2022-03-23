class TwilioSmsDeliveryDetail < DeliveryDetail
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
    delivered? || read? || sent?
  end

  def in_progress?
    queued? || sending?
  end
end
