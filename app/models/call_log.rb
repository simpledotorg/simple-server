class CallLog < ApplicationRecord
  belongs_to :user, optional: true

  enum result: {
    queued: 'queued',
    ringing: 'ringing',
    in_progress: 'in_progress',
    completed: 'completed',
    failed: 'failed',
    busy: 'busy',
    no_answer: 'no_answer'
  }, _prefix: true
end
