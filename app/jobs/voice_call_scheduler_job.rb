# Picks overdue patients at facilities enabled for AI voice calls and queues one call per appointment.
# Enable a facility with `Flipper.enable(:voice_agent_calls, facility.region)`.
class VoiceCallSchedulerJob < ApplicationJob
  queue_as :default

  DEFAULT_DAYS_OVERDUE = 3
  DEFAULT_DAILY_CAP_PER_FACILITY = 50
  RECENT_CALL_RESULT_DAYS = 7

  def perform
    enabled_facilities.each do |facility|
      appointments_to_call(facility).each do |appointment|
        notification = create_notification(appointment)
        VoiceAgent::CallWorker.perform_async(notification.id)
      end
    end
  end

  private

  def enabled_facilities
    region_ids = Flipper.feature(:voice_agent_calls).actors_value.filter_map do |flipper_id|
      klass, id = flipper_id.split(";")
      id if klass == Region.name
    end

    Facility.where(id: Region.facility_regions.where(id: region_ids).select(:source_id))
  end

  # Unlike Appointment.eligible_for_reminders, this does not skip appointments that were sent
  # an SMS reminder. A reminder before the call makes patients more likely to answer.
  def appointments_to_call(facility)
    Appointment
      .overdue_by(ENV.fetch("VOICE_AGENT_DAYS_OVERDUE", DEFAULT_DAYS_OVERDUE).to_i)
      .where(facility: facility)
      .where(patient_id: Patient.contactable.select(:id))
      .where.not(id: voice_called_appointment_ids)
      .where.not(id: recently_called_appointment_ids)
      .order(scheduled_date: :desc)
      .limit(ENV.fetch("VOICE_AGENT_DAILY_CAP_PER_FACILITY", DEFAULT_DAILY_CAP_PER_FACILITY).to_i)
  end

  # Each appointment gets one voice call. Removal suggestions keep it from being called
  # again until a nurse resolves them.
  def voice_called_appointment_ids
    Notification
      .where(purpose: :overdue_voice_call, subject_type: Appointment.name)
      .where.not(subject_id: nil)
      .select(:subject_id)
  end

  def recently_called_appointment_ids
    CallResult
      .where("created_at > ?", RECENT_CALL_RESULT_DAYS.days.ago)
      .where.not(appointment_id: nil)
      .select(:appointment_id)
  end

  def create_notification(appointment)
    Notification.create!(
      subject: appointment,
      patient: appointment.patient,
      remind_on: Date.current,
      status: "scheduled",
      message: "voice_agent.overdue_call",
      purpose: "overdue_voice_call"
    )
  end
end
