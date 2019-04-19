class TwilioSMSDeliveryDetail < ApplicationRecord
  has_one :communication, as: :detailable

  enum result: {
    queued: 'queued',
    failed: 'failed',
    sent: 'sent',
    delivered: 'delivered',
    undelivered: 'undelivered',
    unknown: 'unknown'
  }, _prefix: true
end

