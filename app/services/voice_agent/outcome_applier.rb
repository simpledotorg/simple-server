# Applies a voice agent outcome to the appointment it was requested for.
#
# The AI only makes soft decisions: it can mark a patient as agreed to visit or snooze them.
# Removals are stored as suggestions for a nurse to confirm. `unreached` removes the patient
# as `not_responding` only when :voice_agent_not_responding_removals is enabled; until then
# it runs in shadow mode and is only recorded. Our own failures (`failed`, `expired`) never
# change the appointment.
class VoiceAgent::OutcomeApplier
  def self.call(...)
    new(...).call
  end

  def initialize(voice_call_detail, outcome)
    @voice_call_detail = voice_call_detail
    @outcome = outcome
  end

  # Returns :applied, or :duplicate when an outcome was already received for this call.
  def call
    result = VoiceCallDetail.transaction do
      voice_call_detail.lock!
      next :duplicate unless voice_call_detail.status_requested?

      voice_call_detail.update!(outcome.detail_attributes)
      update_appointment if appointment&.scheduled?
      :applied
    end

    alert_safety_flag if result == :applied && voice_call_detail.safety_flag?
    result
  end

  private

  attr_reader :voice_call_detail, :outcome

  def appointment
    @appointment ||= voice_call_detail.appointment
  end

  def update_appointment
    case appointment_action
    when :agreed_to_visit
      appointment.mark_patient_agreed_to_visit(bot_user)
    when :remind_to_call_later
      appointment.mark_remind_to_call_later(bot_user)
    when :not_responding
      appointment.mark_appointment_cancelled(bot_user, :not_responding)
    else
      return
    end

    # Server-side changes must be newer than the device's copy, or the app's next sync wins the merge.
    appointment.device_updated_at = Time.current
    appointment.save!
    appointment.update_patient_status
  end

  def appointment_action
    if voice_call_detail.status_completed?
      return :remind_to_call_later if voice_call_detail.confidence_low?

      case voice_call_detail.outcome
      when "agreed_to_visit" then :agreed_to_visit
      when "remind_to_call_later" then :remind_to_call_later
      end
    elsif voice_call_detail.status_unreached? && Flipper.enabled?(:voice_agent_not_responding_removals)
      :not_responding
    end
  end

  def bot_user
    @bot_user ||= VoiceAgentUser.find_or_create(org_id: appointment.facility.organization_id)
  end

  def alert_safety_flag
    Metrics.increment("voice_agent_safety_flags")
    Sentry.capture_message(
      "Voice agent safety flag",
      level: :warning,
      extra: {
        voice_call_detail_id: voice_call_detail.id,
        facility_id: appointment&.facility_id
      }
    )
  end
end
