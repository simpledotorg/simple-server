class TwilioSmsDeliveryDetail < ApplicationRecord
  has_one :communication, as: :detailable

  enum result: {
    queued: 'queued',
    failed: 'failed',
    sent: 'sent',
    delivered: 'delivered',
    undelivered: 'undelivered',
    unknown: 'unknown'
  }

  after_commit do
    communication.communication_result = :unsuccessful if unsuccessful?
    communication.communication_result = :successful if successful?
    communication.communication_result = :in_progress if in_progress?
    communication.save!
  end

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
