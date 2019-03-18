class CallLog < ApplicationRecord
  belongs_to :user
  belongs_to :patient_phone_number

  enum result: {
    queued: 'queued',
    ringing: 'cancelled',
    in_progress: 'visited',
    completed: 'completed',
    failed: 'failed',
    busy: 'busy',
    no_answer: 'no_answer'
  }, _prefix: true
end
