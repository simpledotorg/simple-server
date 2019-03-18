class Appointment < ApplicationRecord
  include Mergeable

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
    if new_call_result == 'agreed_to_visit'
      self.agreed_to_visit = true
      self.remind_on = 30.days.from_now
    elsif new_call_result == 'patient_has_already_visited'
      self.status = :visited
      self.agreed_to_visit = nil
      self.remind_on = nil
    elsif new_call_result == 'remind_to_call_later'
      self.remind_on = 7.days.from_now
    elsif Appointment.cancel_reasons.values.include?(new_call_result)
      self.agreed_to_visit = false
      self.remind_on = nil
      self.cancel_reason = new_call_result
      self.status = :cancelled
    end

    if new_call_result == 'dead'
      self.patient.status = 'dead'
    end

    super(new_call_result)
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
end
