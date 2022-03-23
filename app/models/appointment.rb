require "csv"

class Appointment < ApplicationRecord
  include ApplicationHelper
  include Mergeable
  include Hashable

  belongs_to :patient, optional: true
  belongs_to :user, optional: true
  belongs_to :facility
  belongs_to :creation_facility, class_name: "Facility", optional: true

  has_many :notifications, as: :subject
  has_many :call_results

  ANONYMIZED_DATA_FIELDS = %w[id patient_id created_at registration_facility_name user_id scheduled_date
    overdue status agreed_to_visit remind_on]

  enum status: {
    scheduled: "scheduled",
    cancelled: "cancelled",
    visited: "visited"
  }, _prefix: true

  enum cancel_reason: CallResult.remove_reasons.except(:already_visited)

  enum appointment_type: {
    manual: "manual",
    automatic: "automatic"
  }, _prefix: true

  validate :cancel_reason_is_present_if_cancelled
  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true
  validates :appointment_type, presence: true

  scope :for_sync, -> { with_discarded }

  alias_attribute :recorded_at, :device_created_at

  def self.between(start_date, end_date)
    where("scheduled_date BETWEEN ? and ?", start_date, end_date)
  end

  def self.passed_unvisited
    # Scheduled or cancelled appointments whose scheduled date has passed.
    where.not(appointments: {status: :visited})
      .where("appointments.scheduled_date < ?", Date.current)
      .joins(:patient)
      .where.not(patients: {status: :dead})
  end

  def self.last_year_unvisited
    passed_unvisited.where("appointments.scheduled_date >= ?", 365.days.ago)
  end

  def self.all_overdue
    passed_unvisited
      .where(status: :scheduled)
      .where(arel_table[:remind_on].eq(nil).or(arel_table[:remind_on].lteq(Date.current)))
  end

  def self.overdue
    all_overdue.where("appointments.scheduled_date >= ?", 365.days.ago)
  end

  def self.overdue_by(number_of_days)
    overdue.where("scheduled_date <= ?", Date.current - number_of_days.days)
  end

  def self.eligible_for_reminders(days_overdue: 3)
    overdue_by(days_overdue)
      .joins(:patient)
      .merge(Patient.contactable)
      .left_joins(:notifications)
      .where(notifications: {id: nil})
  end

  def days_overdue
    [0, (Date.current - scheduled_date).to_i].max
  end

  def follow_up_days
    [0, (scheduled_date - device_created_at.to_date).to_i].max
  end

  def scheduled?
    status.to_sym == :scheduled
  end

  def overdue?
    scheduled? && scheduled_date <= Date.current
  end

  def overdue_for_over_a_year?
    scheduled? && scheduled_date < 365.days.ago
  end

  def overdue_for_under_a_month?
    scheduled? && scheduled_date > 30.days.ago
  end

  def mark_remind_to_call_later(user)
    self.remind_on = 7.days.from_now
    create_call_result(user, :remind_to_call_later)
  end

  def mark_patient_agreed_to_visit(user)
    self.agreed_to_visit = true
    self.remind_on = 30.days.from_now
    create_call_result(user, :agreed_to_visit)
  end

  def mark_appointment_cancelled(user, cancel_reason)
    self.agreed_to_visit = false
    self.remind_on = nil
    self.cancel_reason = cancel_reason
    self.status = :cancelled
    create_call_result(user, :removed_from_overdue_list, cancel_reason)
  end

  def mark_patient_already_visited(user)
    self.status = :visited
    self.agreed_to_visit = nil
    self.remind_on = nil
    create_call_result(user, :removed_from_overdue_list, :already_visited)
  end

  def update_patient_status
    return unless patient

    case cancel_reason
      when "dead"
        patient.update(status: :dead)
      when "moved_to_private"
        patient.update(status: :migrated)
      when "public_hospital_transfer"
        patient.update(status: :migrated)
      else
        patient.update(status: :active)
    end
  end

  def anonymized_data
    {id: hash_uuid(id),
     patient_id: hash_uuid(patient_id),
     created_at: created_at,
     registration_facility_name: facility.name,
     user_id: hash_uuid(patient&.registration_user&.id),
     scheduled_date: scheduled_date,
     overdue: days_overdue > 0 ? "Yes" : "No",
     status: status,
     agreed_to_visit: agreed_to_visit,
     remind_on: remind_on}
  end

  private

  def cancel_reason_is_present_if_cancelled
    if status == :cancelled && !cancel_reason.present?
      errors.add(:cancel_reason, "should be present for cancelled appointments")
    end
  end

  def create_call_result(user, result_type, remove_reason = nil)
    call_results.create(user: user,
      result_type: result_type,
      remove_reason: remove_reason,
      device_created_at: Time.current,
      device_updated_at: Time.current)
  end
end
