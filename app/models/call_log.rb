class CallLog < ApplicationRecord
  belongs_to :user, optional: true

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
  }, _prefix: true
end
