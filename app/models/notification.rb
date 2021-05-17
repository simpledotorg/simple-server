class Notification < ApplicationRecord
  belongs_to :appointment
  belongs_to :patient
  belongs_to :experiment, class_name: "Experimentation::Experiment", optional: true
  belongs_to :reminder_template, class_name: "Experimentation::ReminderTemplate", optional: true
  has_many :communications

  validates :status, presence: true
  validates :remind_on, presence: true
  validates :message, presence: true

  enum status: {
    pending: "pending",
    scheduled: "scheduled",
    sent: "sent",
    cancelled: "cancelled"
  }, _prefix: true

  scope :due_today, -> { where(remind_on: Date.current, status: [:pending]) }

  def localized_message
    I18n.t(
      message,
      facility_name: appointment.facility.name,
      patient_name: patient.full_name,
      appointment_date: appointment.scheduled_date,
      locale: appointment.facility.locale
    )
  end

  def next_communication_type
    if preferred_communication_method && !previously_communicated_by?(preferred_communication_method)
      return preferred_communication_method
    end
    unless previously_communicated_by?(backup_communication_method)
      return backup_communication_method
    end
    nil
  end

  private

  def previously_communicated_by?(method)
    communications.any? { |communication| communication.communication_type == method }
  end

  def preferred_communication_method
    CountryConfig.current[:name] == "India" ? "missed_visit_whatsapp_reminder" : nil
  end

  def backup_communication_method
    "missed_visit_sms_reminder"
  end
end
