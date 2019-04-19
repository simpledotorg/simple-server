class Patient < ApplicationRecord
  include Mergeable

  GENDERS = %w[male female transgender].freeze
  STATUSES = %w[active dead migrated unresponsive inactive].freeze
  RISK_PRIORITIES = {
    HIGHEST: 0,
    VERY_HIGH: 1,
    HIGH: 2,
    REGULAR: 3,
    LOW: 4,
    NONE: 5
  }.freeze

  belongs_to :address, optional: true
  has_many :phone_numbers, class_name: 'PatientPhoneNumber'
  has_many :blood_pressures, inverse_of: :patient
  has_many :latest_blood_pressures, -> { order(device_created_at: :desc) }, class_name: 'BloodPressure'
  has_many :prescription_drugs
  has_many :facilities, -> { distinct }, through: :blood_pressures
  has_many :users, -> { distinct }, through: :blood_pressures

  belongs_to :registration_facility, class_name: "Facility", optional: true
  belongs_to :registration_user, class_name: "User"

  has_many :appointments
  has_one :medical_history

  attribute :call_result, :string

  enum could_not_contact_reasons: {
    not_responding: 'not_responding',
    moved: 'moved',
    dead: 'dead',
    invalid_phone_number: 'invalid_phone_number',
    public_hospital_transfer: 'public_hospital_transfer',
    moved_to_private: 'moved_to_private',
    other: 'other'
  }

  validate :past_date_of_birth

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true

  validates_associated :address, if: :address
  validates_associated :phone_numbers, if: :phone_numbers

  def past_date_of_birth
    if date_of_birth.present? && date_of_birth > Date.today
      errors.add(:date_of_birth, "can't be in the future")
    end
  end

  def latest_scheduled_appointment
    appointments.where(status: 'scheduled').order(scheduled_date: :desc).first
  end

  def latest_blood_pressure
    latest_blood_pressures.first
  end

  def risk_priority
    return RISK_PRIORITIES[:NONE] if latest_scheduled_appointment.overdue_for_under_a_month?

    if latest_blood_pressure&.critical?
      RISK_PRIORITIES[:HIGHEST]
    elsif medical_history&.indicates_risk?
      RISK_PRIORITIES[:VERY_HIGH]
    elsif latest_blood_pressure&.very_high?
      RISK_PRIORITIES[:HIGH]
    elsif latest_blood_pressure&.high?
      RISK_PRIORITIES[:REGULAR]
    elsif low_priority?
      RISK_PRIORITIES[:LOW]
    else
      RISK_PRIORITIES[:NONE]
    end
  end

  def risk_priority_label
    case risk_priority
    when RISK_PRIORITIES[:HIGHEST] then "Critical"
    when RISK_PRIORITIES[:VERY_HIGH] then "Very high"
    when RISK_PRIORITIES[:HIGH] then "High"
    else nil
    end
  end

  def high_risk?
    [RISK_PRIORITIES[:HIGHEST],
     RISK_PRIORITIES[:VERY_HIGH],
     RISK_PRIORITIES[:HIGH]].include?(risk_priority)
  end

  def current_age
    if date_of_birth.present?
      Date.today.year - date_of_birth.year
    elsif age.present?
      return 0 if age == 0

      years_since_update = Date.today.year - age_updated_at.year
      age + years_since_update
    end
  end

  def call_result=(new_call_result)
    if new_call_result == 'contacted'
      self.contacted_by_counsellor = true
    elsif Patient.could_not_contact_reasons.values.include?(new_call_result)
      self.contacted_by_counsellor = false
      self.could_not_contact_reason = new_call_result
    end

    if new_call_result == 'dead'
      self.status = 'dead'
    end

    super(new_call_result)
  end

  def self.not_contacted
    where(contacted_by_counsellor: false)
      .where(could_not_contact_reason: nil)
      .where('device_created_at <= ?', 2.days.ago)
  end

  def latest_phone_number
    phone_numbers.last.number
  end

  private

  def low_priority?
    latest_scheduled_appointment.overdue_for_over_a_year? &&
      latest_blood_pressure&.under_control?
  end
end
