class AppointmentReminder < ApplicationRecord
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

  def next_communication_type
    if preferred_communication_method && !has_been_communicated_via?(preferred_communication_method)
      return preferred_communication_method
    end
    unless has_been_communicated_via?(backup_communication_method)
      return backup_communication_method
    end
    nil
  end

  private

  def has_been_communicated_via?(method)
    communications.any? { |communication| communication.communication_type == method }
  end

  def preferred_communication_method
    CountryConfig.current[:name] == "India" ? "missed_visit_whatsapp_reminder" : nil
  end

  def backup_communication_method
    "missed_visit_sms_reminder"
  end
end
