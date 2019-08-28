require 'csv'

class Appointment < ApplicationRecord
  include ApplicationHelper
  include Mergeable
  include Hashable

  belongs_to :patient, optional: true
  belongs_to :facility

  has_many :communications

  ANONYMIZED_DATA_FIELDS = %w[id patient_id created_at registration_facility_name user_id scheduled_date
                              overdue status agreed_to_visit remind_on]

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

  validate :cancel_reason_is_present_if_cancelled
  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true

  def self.overdue
    where(status: 'scheduled')
      .where('scheduled_date <= ?', Date.today)
      .where('remind_on IS NULL OR remind_on <= ?', Date.today)
  end

  def self.overdue_by(number_of_days)
    overdue.where('scheduled_date <= ?', Date.today - number_of_days.days)
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

  def anonymized_data
    { id: hash_uuid(id),
      patient_id: hash_uuid(patient_id),
      created_at: created_at,
      registration_facility_name: facility.name,
      user_id: hash_uuid(patient&.registration_user&.id),
      scheduled_date: scheduled_date,
      overdue: days_overdue > 0 ? 'Yes' : 'No',
      status: status,
      agreed_to_visit: agreed_to_visit,
      remind_on: remind_on
    }
  end

  # CSV export
  def self.to_csv
    appointments = all.joins(patient: { latest_blood_pressures: :facility })
                     .includes(patient: [:address, :phone_numbers, :medical_history,
                                         { latest_blood_pressures: :facility }])

    CSV.generate(headers: true) do |csv|
      csv << csv_headers

      appointments.group_by { |a| a.patient.latest_blood_pressure.facility }.each do |_, facility_appointments|
        facility_appointments.sort_by { |a| a.patient.risk_priority }.each do |appointment|
          csv << appointment.csv_fields
        end
      end
    end
  end

  def self.csv_headers
    [
      "Patient name",
      "Gender",
      "Age",
      "Days overdue",
      "Registration date",
      "Last BP",
      "Last BP taken at",
      "Last BP date",
      "Risk level",
      "Patient address",
      "Patient village or colony",
      "Patient phone"
    ].freeze
  end

  def csv_fields
    [
      patient.full_name,
      patient.gender.capitalize,
      patient.current_age,
      days_overdue,
      patient.registration_date,
      patient.latest_blood_pressure.to_s,
      patient.latest_blood_pressure.facility.name,
      display_date(patient.latest_blood_pressure.recorded_at),
      patient.risk_priority_label,
      patient.address.street_address,
      patient.address.village_or_colony,
      patient.phone_numbers.first&.number
    ]
  end

  def previously_communicated_via?(communication_type)
    communications.latest_by_type(communication_type)&.attempted?
  end
end
