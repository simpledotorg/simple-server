require 'csv'

class Appointment < ApplicationRecord
  include Mergeable

  belongs_to :patient, optional: true
  belongs_to :facility

  has_many :communications

  enum status: {
    scheduled: 'scheduled',
    cancelled: 'cancelled',
    visited: 'visited'
  }, _prefix: true

  enum cancel_reason: {
    not_responding: 'not_responding',
    moved: 'moved',
    dead: 'dead',
    invalid_phone_number: 'invalid_phone_number',
    public_hospital_transfer: 'public_hospital_transfer',
    moved_to_private: 'moved_to_private',
    other: 'other'
  }

  enum appointment_type: {
    manual: 'manual',
    automatic: 'automatic'
  }, _prefix: true

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true
  validate :cancel_reason_is_present_if_cancelled

  def self.overdue
    where(status: 'scheduled')
      .where('scheduled_date <= ?', Date.today)
      .where('remind_on IS NULL OR remind_on <= ?', Date.today)
  end

  def self.to_csv
    headers = [
      "Patient name",
      "Gender",
      "Age",
      "Days overdue",
      "Last BP",
      "Last BP taken at",
      "Last BP date",
      "Risk level",
      "Patient address",
      "Patient village or colony",
      "Patient phone"
    ].freeze

    CSV.generate(headers: true) do |csv|
      csv << headers

      all.group_by { |a| a.patient.latest_blood_pressure.facility }.each do |facility, facility_appointments|
        facility_appointments.sort_by { |a| a.patient.risk_priority }.each do |appointment|
          csv << [
            appointment.patient.full_name,
            appointment.patient.gender.capitalize,
            appointment.patient.current_age,
            appointment.days_overdue,
            appointment.patient.latest_blood_pressure.to_s,
            appointment.patient.latest_blood_pressure.facility.name,
            appointment.patient.latest_blood_pressure.device_created_at.to_date,
            appointment.patient.risk_priority_label,
            appointment.patient.address.street_address,
            appointment.patient.address.village_or_colony,
            appointment.patient.phone_numbers.first&.number
          ]
        end
      end
    end
  end

  def days_overdue
    (Date.today - scheduled_date).to_i
  end

  def scheduled?
    status.to_sym == :scheduled
  end

  def overdue?
    scheduled? && scheduled_date <= Date.today
  end

  def overdue_for_over_a_year?
    scheduled? && scheduled_date < 365.days.ago
  end

  def overdue_for_under_a_month?
    scheduled? && scheduled_date > 30.days.ago
  end

  def cancel_reason_is_present_if_cancelled
    if status == :cancelled && !cancel_reason.present?
      errors.add(:cancel_reason, 'should be present for cancelled appointments')
    end
  end

  def mark_remind_to_call_later
    self.remind_on = 7.days.from_now
  end

  def mark_patient_agreed_to_visit
    self.agreed_to_visit = true
    self.remind_on = 30.days.from_now
  end

  def mark_appointment_cancelled(cancel_reason)
    self.agreed_to_visit = false
    self.remind_on = nil
    self.cancel_reason = cancel_reason
    self.status = :cancelled
  end

  def mark_patient_already_visited
    self.status = :visited
    self.agreed_to_visit = nil
    self.remind_on = nil
  end

  def mark_patient_as_dead
    self.patient.status = :dead
    self.patient.save
  end
end
