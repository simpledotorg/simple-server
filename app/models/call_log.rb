class CallLog < ApplicationRecord
  validates :caller_phone_number, presence: true
  validates :callee_phone_number, presence: true

  enum result: {
    queued: 'queued',
    ringing: 'ringing',
    in_progress: 'in_progress',
    completed: 'completed',
    failed: 'failed',
    busy: 'busy',
    no_answer: 'no_answer',
    canceled: 'canceled',
    unknown: 'unknown'
  }, _prefix: true
end
