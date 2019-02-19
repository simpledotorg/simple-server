class Appointment < ApplicationRecord
  include Mergeable

  RISK_LEVELS = {
    HIGHEST: 0,
    VERY_HIGH: 1,
    HIGH: 2,
    REGULAR: 3,
    LOW: 4,
    NONE: 5
  }.freeze

  belongs_to :patient, optional: true
  belongs_to :facility

  has_many :communications

  attribute :call_result, :string

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

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true
  validate :cancel_reason_is_present_if_cancelled

  def self.overdue
    where(status: 'scheduled')
      .where('scheduled_date <= ?', Date.today)
      .where('remind_on IS NULL OR remind_on <= ?', Date.today)
  end

  def call_result=(new_call_result)
    if new_call_result == "agreed_to_visit"
      self.agreed_to_visit = true
      self.remind_on = 30.days.from_now
    elsif new_call_result == "remind_to_call_later"
      self.remind_on = 7.days.from_now
    elsif Appointment.cancel_reasons.values.include?(new_call_result)
      self.agreed_to_visit = false
      self.remind_on = nil
      self.cancel_reason = new_call_result
      self.status = :cancelled
    end

    if new_call_result == "dead"
      self.patient.status = "dead"
    end

    super(new_call_result)
  end

  def patient_risk_priority
    return RISK_LEVELS[:NONE] if days_overdue < 30 || low_risk_priority_patient?
    patient_risk_level
  end

  def high_risk_priority_patient?
    [RISK_LEVELS[:HIGHEST],
     RISK_LEVELS[:VERY_HIGH],
     RISK_LEVELS[:HIGH]].include?(patient_risk_priority)
  end

  def low_risk_priority_patient?
    patient_risk_level == RISK_LEVELS[:NONE] && days_overdue < 365
  end

  def days_overdue
    (Date.today - scheduled_date).to_i
  end

  def overdue?
    status.to_sym == :scheduled && scheduled_date <= Date.today
  end

  def cancel_reason_is_present_if_cancelled
    if status == :cancelled && !cancel_reason.present?
      errors.add(:cancel_reason, "should be present for cancelled appointments")
    end
  end

  def patient_risk_level
    latest_blood_pressure = patient.latest_blood_pressure

    if latest_blood_pressure&.critically_hypertensive?
      RISK_LEVELS[:HIGHEST]

    elsif patient&.medical_history&.risk_history?
      RISK_LEVELS[:VERY_HIGH]

    elsif latest_blood_pressure&.severely_hypertensive?
      RISK_LEVELS[:HIGH]

    elsif latest_blood_pressure&.hypertensive?
      RISK_LEVELS[:REGULAR]

    elsif latest_blood_pressure&.under_control?
      RISK_LEVELS[:LOW]

    else
      RISK_LEVELS[:NONE]
    end
  end
end
