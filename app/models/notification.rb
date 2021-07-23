class Notification < ApplicationRecord
  belongs_to :subject, optional: true, polymorphic: true
  belongs_to :patient
  belongs_to :experiment, class_name: "Experimentation::Experiment", optional: true
  belongs_to :reminder_template, class_name: "Experimentation::ReminderTemplate", optional: true
  has_many :communications

  APPOINTMENT_REMINDER_MSG_PREFIX = "communications.appointment_reminders"

  validates :status, presence: true
  validates :remind_on, presence: true
  validates :message, presence: true
  validates :purpose, presence: true

  enum status: {
    pending: "pending",
    scheduled: "scheduled",
    sent: "sent",
    cancelled: "cancelled"
  }, _prefix: true
  enum purpose: {
    covid_medication_reminder: "covid_medication_reminder",
    experimental_appointment_reminder: "experimental_appointment_reminder",
    missed_visit_reminder: "missed_visit_reminder"
  }

  scope :due_today, -> { where(remind_on: Date.current, status: [:pending]) }

  def localized_message
    case purpose
    when "missed_visit_reminder", "experimental_appointment_reminder"
      I18n.t(
        message,
        facility_name: subject.facility.name,
        patient_name: patient.full_name,
        appointment_date: subject.scheduled_date,
        locale: subject.facility.locale
      )
    when "covid_medication_reminder"
      I18n.t(
        message,
        facility_name: patient.assigned_facility.name,
        patient_name: patient.full_name,
        locale: patient.assigned_facility.locale
      )
    else
      raise ArgumentError, "No localized_message defined for notification of type #{purpose}"
    end
  end

  def next_communication_type
    # guarding against experiment state to prevent race condition
    return nil if status_cancelled? || experiment&.cancelled_state?
    if preferred_communication_method && !previously_communicated_by?(preferred_communication_method)
      return preferred_communication_method
    end
    return backup_communication_method unless previously_communicated_by?(backup_communication_method)
    nil
  end

  private

  def previously_communicated_by?(method)
    communications.any? { |communication| communication.communication_type == method }
  end

  def preferred_communication_method
    return "whatsapp" if Flipper.enabled?(:whatsapp_appointment_reminders)
    return "imo" if Flipper.enabled?(:imo_messaging) && patient.imo_authorization&.status_subscribed?
    nil
  end

  def backup_communication_method
    "sms"
  end
end
