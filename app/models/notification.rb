class PatientNotification < ApplicationRecord
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

  def payload_for_bsnl

  end

  def self.cancel
    where(status: %w[pending scheduled]).update_all(status: :cancelled)
  end

  def successful_deliveries
    communications.with_delivery_detail.select("delivery_detail.result, communications.*").where(
      delivery_detail: {result: [:read, :delivered, :sent]}
    )
  end

  def queued_deliveries
    communications.with_delivery_detail.select("delivery_detail.result, communications.*").where(
      delivery_detail: {result: [:queued]}
    )
  end

  def delivery_result
    if status_cancelled?
      :failed
    elsif successful_deliveries.exists?
      :success
    elsif queued_deliveries.exists? || !communications.exists?
      :queued
    else
      :failed
    end
  end
end
