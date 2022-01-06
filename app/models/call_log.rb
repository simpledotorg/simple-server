# frozen_string_literal: true

class CallLog < ApplicationRecord
  include Hashable

  validates :caller_phone_number, presence: true
  validates :callee_phone_number, presence: true

  ANONYMIZED_DATA_FIELDS = %w[id created_at result duration start_time end_time]

  enum result: {
    queued: "queued",
    ringing: "ringing",
    in_progress: "in_progress",
    completed: "completed",
    failed: "failed",
    busy: "busy",
    no_answer: "no_answer",
    canceled: "canceled",
    unknown: "unknown"
  }, _prefix: true

  def anonymized_data
    {id: hash_uuid(id),
     created_at: created_at,
     result: result,
     duration: duration,
     start_time: start_time,
     end_time: end_time}
  end
end
