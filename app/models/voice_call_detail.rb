class VoiceCallDetail < DeliveryDetail
  # Reasons the voice agent may suggest for removing a patient from the overdue list.
  # These are never applied automatically; a nurse confirms them from the review queue.
  # `not_responding` comes from the `unreached` status instead, and `other` is too vague to act on.
  SUGGESTED_REMOVE_REASONS = CallResult.remove_reasons.keys - %w[not_responding other]

  belongs_to :resolved_by_user, class_name: "User", optional: true

  enum status: {
    requested: "requested",
    completed: "completed",
    unreached: "unreached",
    expired: "expired",
    failed: "failed"
  }, _prefix: true

  enum outcome: {
    agreed_to_visit: "agreed_to_visit",
    remind_to_call_later: "remind_to_call_later",
    removal_suggested: "removal_suggested"
  }, _prefix: true

  enum confidence: {
    high: "high",
    low: "low"
  }, _prefix: true

  validates :call_request_id, presence: true, uniqueness: true
  validates :status, presence: true

  scope :in_progress, -> { status_requested }
  scope :pending_review, -> { status_completed.outcome_removal_suggested.confidence_high.where(resolved_at: nil) }

  def successful?
    status_completed?
  end

  def unsuccessful?
    status_unreached? || status_expired? || status_failed?
  end

  def in_progress?
    status_requested?
  end

  def result
    status
  end

  def appointment
    communication&.notification&.subject
  end

  def self.create_with_communication!(call_request_id:)
    ActiveRecord::Base.transaction do
      voice_call_detail = create!(call_request_id: call_request_id, status: :requested)

      Communication.create!(
        communication_type: Messaging::VoiceAgent::Call.communication_type,
        detailable: voice_call_detail
      )
    end
  end
end
