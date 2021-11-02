class Notification < ApplicationRecord
  belongs_to :subject, optional: true, polymorphic: true
  belongs_to :patient
  belongs_to :experiment, class_name: "Experimentation::Experiment", optional: true
  belongs_to :reminder_template, class_name: "Experimentation::ReminderTemplate", optional: true
  has_many :communications

  # A common logger for all notification related things - adding the top level module tag here will
  # make things easy to scan for in Datadog.
  def self.logger(extra_fields = {})
    fields = {module: :notifications}.merge(extra_fields)
    Rails.logger.child(fields)
  end

  APPOINTMENT_REMINDER_MSG_PREFIX = "communications.appointment_reminders"

  validates :status, presence: true
  validates :remind_on, presence: true
  validates :message, presence: true
  validates :purpose, presence: true
  validates :subject, presence: true, if: proc { |n| n.missed_visit_reminder? }, on: :create

  enum status: {
    pending: "pending",
    scheduled: "scheduled",
    sent: "sent",
    cancelled: "cancelled"
  }, _prefix: true
  enum purpose: {
    covid_medication_reminder: "covid_medication_reminder",
    experimental_appointment_reminder: "experimental_appointment_reminder",
    missed_visit_reminder: "missed_visit_reminder",
    test_message: "test_message"
  }

  scope :due_today, -> { where(remind_on: Date.current, status: [:pending]) }

  def localized_message
    return unless patient

    case purpose
    when "covid_medication_reminder"
      I18n.t(
        message,
        facility_name: patient.assigned_facility.name,
        patient_name: patient.full_name,
        locale: patient.locale
      )
    when "experimental_appointment_reminder"
      facility = subject&.facility || patient.assigned_facility
      I18n.t(
        message,
        facility_name: facility.name,
        patient_name: patient.full_name,
        appointment_date: subject&.scheduled_date,
        locale: facility.locale
      )
    when "missed_visit_reminder"
      I18n.t(
        message,
        facility_name: subject.facility.name,
        patient_name: patient.full_name,
        appointment_date: subject.scheduled_date,
        locale: subject.facility.locale
      )
    when "test_message"
      "Test message sent by Simple.org to #{patient.full_name}"
    else
      raise ArgumentError, "No localized_message defined for notification of type #{purpose}"
    end
  end

  def next_communication_type
    return nil if status_cancelled?
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
