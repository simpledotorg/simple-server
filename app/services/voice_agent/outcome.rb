# The result the voice agent posts back for one call request. It carries no transcript,
# no free text and no audio.
class VoiceAgent::Outcome
  include ActiveModel::Model
  include ActiveModel::Attributes

  STATUSES = VoiceCallDetail.statuses.keys - %w[requested]
  OUTCOMES = VoiceCallDetail.outcomes.keys
  CONFIDENCES = VoiceCallDetail.confidences.keys
  COUNTERS = %i[attempts answered_attempts connected_seconds]

  attribute :call_request_id, :string
  attribute :status, :string
  attribute :outcome, :string
  attribute :suggested_remove_reason, :string
  attribute :safety_flag, :boolean, default: false
  attribute :confidence, :string
  attribute :attempts
  attribute :answered_attempts
  attribute :last_attempted_at
  attribute :connected_seconds
  attribute :provider, :string
  attribute :prompt_version, :string

  validates :call_request_id, presence: true
  validates :status, inclusion: {in: STATUSES}
  validates :outcome, inclusion: {in: OUTCOMES}, if: :completed?
  validates :outcome, absence: true, unless: :completed?
  validates :confidence, inclusion: {in: CONFIDENCES}, if: :completed?
  validates :suggested_remove_reason, inclusion: {in: VoiceCallDetail::SUGGESTED_REMOVE_REASONS}, if: :removal_suggested?
  validates :suggested_remove_reason, absence: true, unless: :removal_suggested?
  validates(*COUNTERS, numericality: {only_integer: true, greater_than_or_equal_to: 0}, allow_nil: true)
  validate :last_attempted_at_is_a_time

  def safety_flag
    super || false
  end

  def completed?
    status == "completed"
  end

  def removal_suggested?
    completed? && outcome == "removal_suggested"
  end

  def detail_attributes
    {
      status: status,
      outcome: outcome,
      suggested_remove_reason: suggested_remove_reason,
      safety_flag: safety_flag,
      confidence: confidence,
      attempts: attempts,
      answered_attempts: answered_attempts,
      last_attempted_at: parsed_last_attempted_at,
      connected_seconds: connected_seconds,
      provider: provider,
      prompt_version: prompt_version
    }
  end

  private

  def parsed_last_attempted_at
    return if last_attempted_at.blank?

    Time.zone.iso8601(last_attempted_at.to_s)
  rescue ArgumentError
    nil
  end

  def last_attempted_at_is_a_time
    return if last_attempted_at.blank? || parsed_last_attempted_at

    errors.add(:last_attempted_at, "must be an ISO 8601 timestamp")
  end
end
