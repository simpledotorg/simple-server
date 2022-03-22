class Patient < ApplicationRecord
  include ApplicationHelper
  include Mergeable
  include Hashable
  include PatientReportable

  GENDERS = Rails.application.config.country[:supported_genders].freeze
  STATUSES = %w[active dead migrated unresponsive inactive].freeze
  RISK_PRIORITIES = {
    HIGH: 0,
    REGULAR: 1
  }.freeze

  ANONYMIZED_DATA_FIELDS = %w[id created_at registration_date registration_facility_name user_id age gender]
  DELETED_REASONS = %w[duplicate unknown accidental_registration].freeze

  enum status: STATUSES.zip(STATUSES).to_h, _prefix: true

  enum reminder_consent: {
    granted: "granted",
    denied: "denied"
  }, _prefix: true

  enum could_not_contact_reasons: {
    not_responding: "not_responding",
    moved: "moved",
    dead: "dead",
    invalid_phone_number: "invalid_phone_number",
    public_hospital_transfer: "public_hospital_transfer",
    moved_to_private: "moved_to_private",
    other: "other"
  }

  belongs_to :address, optional: true
  has_many :phone_numbers, class_name: "PatientPhoneNumber"
  has_many :business_identifiers, class_name: "PatientBusinessIdentifier"
  has_many :passport_authentications, through: :business_identifiers

  has_many :blood_pressures, inverse_of: :patient
  has_many :blood_sugars
  has_many :prescription_drugs
  has_many :facilities, -> { distinct }, through: :blood_pressures
  has_many :users, -> { distinct }, through: :blood_pressures
  has_many :appointments
  has_many :notifications
  has_many :treatment_group_memberships, class_name: "Experimentation::TreatmentGroupMembership"
  has_many :treatment_groups, through: :treatment_group_memberships, class_name: "Experimentation::TreatmentGroup"
  has_many :experiments, through: :treatment_groups, class_name: "Experimentation::Experiment"
  has_one :medical_history
  has_many :teleconsultations

  has_many :encounters
  has_many :observations, through: :encounters

  belongs_to :registration_facility, class_name: "Facility", optional: true
  belongs_to :assigned_facility, class_name: "Facility", optional: true
  belongs_to :registration_user, class_name: "User"

  has_many :latest_blood_pressures, -> { order(recorded_at: :desc) }, class_name: "BloodPressure"
  has_many :latest_blood_sugars, -> { order(recorded_at: :desc) }, class_name: "BloodSugar"

  has_many :latest_scheduled_appointments,
    -> { where(status: "scheduled").order(scheduled_date: :desc) },
    class_name: "Appointment"

  has_many :latest_bp_passports,
    -> { where(identifier_type: "simple_bp_passport").order(device_created_at: :desc) },
    class_name: "PatientBusinessIdentifier"

  has_many :current_prescription_drugs, -> { where(is_deleted: false).order(created_at: :desc) }, class_name: "PrescriptionDrug"

  has_many :patient_states, class_name: "Reports::PatientState"

  belongs_to :deleted_by_user, class_name: "User", optional: true

  attribute :call_result, :string

  scope :with_nested_sync_resources, -> { includes(:address, :phone_numbers, :business_identifiers) }
  scope :for_sync, -> { with_discarded.with_nested_sync_resources }
  scope :search_by_address, ->(term) { joins(:address).merge(Address.search_by_street_or_village(term)) }

  scope :follow_ups_by_period, ->(period, at_region: nil, current: true, last: nil) {
    FollowUpsQuery.new.with(Encounter, period, at_region: at_region, time_column: "encountered_on", current: current, last: last, time_zone: false)
  }

  scope :diabetes_follow_ups_by_period, ->(period, at_region: nil, current: true, last: nil) {
    FollowUpsQuery.new.with(BloodSugar, period, at_region: at_region, current: current, last: last).with_diabetes
  }

  scope :hypertension_follow_ups_by_period, ->(period, at_region: nil, current: true, last: nil) {
    FollowUpsQuery.new.with(BloodPressure, period, at_region: at_region, current: current, last: last).with_hypertension
  }

  scope :contactable, -> {
    # We don't want to add the device_created_at ORDER BY default scope from PatientPhoneNumber just for grabbing contactable records, so we do unscoped here
    where(reminder_consent: "granted")
      .where.not(status: "dead")
      .joins(:phone_numbers)
      .merge(PatientPhoneNumber.unscoped.phone_type_mobile)
  }

  scope :where_current_age, ->(comparison_operator, age) do
    # comparison_operator is any of the SQL comparison operators (=, > etc.)
    where("EXTRACT(YEAR
            FROM COALESCE(
              age('#{Date.today}', date_of_birth),
              make_interval(years => age) + age('#{Date.today}', age_updated_at))) #{comparison_operator} #{age}")
  end

  validate :past_date_of_birth
  validates :status, presence: true

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true

  validates_associated :address, if: :address
  validates_associated :phone_numbers, if: :phone_numbers

  delegate :locale, to: :assigned_facility

  def current_age
    if date_of_birth.present?
      ((Time.zone.now.beginning_of_day - date_of_birth.beginning_of_day) / 1.year).floor
    elsif age.present?
      years_since_update = (Time.current - age_updated_at) / 1.year
      (age + years_since_update).floor
    end
  end

  def past_date_of_birth
    if date_of_birth.present? && date_of_birth > Date.current
      errors.add(:date_of_birth, "can't be in the future")
    end
  end

  def latest_scheduled_appointment
    latest_scheduled_appointments.first
  end

  def latest_blood_pressure
    latest_blood_pressures.first
  end

  def latest_blood_sugar
    latest_blood_sugars.first
  end

  def latest_phone_number
    phone_numbers.last&.number
  end

  def latest_mobile_number
    phone_numbers.phone_type_mobile.last&.localized_phone_number
  end

  def latest_bp_passport
    latest_bp_passports.first
  end

  def access_tokens
    passport_authentications.map(&:access_token)
  end

  def phone_number?
    latest_phone_number.present?
  end

  def registration_date
    handle_impossible_registration_date(recorded_at)
  end

  def risk_priority
    return RISK_PRIORITIES[:REGULAR] if latest_scheduled_appointment&.overdue_for_under_a_month?

    if latest_blood_pressure&.critical?
      RISK_PRIORITIES[:HIGH]
    elsif medical_history&.indicates_hypertension_risk? && latest_blood_pressure&.hypertensive?
      RISK_PRIORITIES[:HIGH]
    elsif latest_blood_sugar&.diabetic?
      RISK_PRIORITIES[:HIGH]
    else
      RISK_PRIORITIES[:REGULAR]
    end
  end

  def high_risk?
    risk_priority == RISK_PRIORITIES[:HIGH]
  end

  def call_result=(new_call_result)
    if new_call_result == "contacted"
      self.contacted_by_counsellor = true
    elsif Patient.could_not_contact_reasons.value?(new_call_result)
      self.contacted_by_counsellor = false
      self.could_not_contact_reason = new_call_result
    end

    if new_call_result == "dead"
      self.status = "dead"
    end

    super(new_call_result)
  end

  def prescribed_drugs(date: Date.current)
    prescription_drugs.prescribed_as_of(date)
  end

  def self.not_contacted
    where(contacted_by_counsellor: false)
      .where(could_not_contact_reason: nil)
      .where("device_created_at <= ?", 2.days.ago)
  end

  def anonymized_data
    {id: hash_uuid(id),
     created_at: created_at,
     registration_date: recorded_at,
     registration_facility_name: registration_facility&.name,
     user_id: hash_uuid(registration_user&.id),
     age: age,
     gender: gender}
  end

  def discard_data
    ActiveRecord::Base.transaction do
      address&.discard
      appointments.discard_all
      blood_pressures.discard_all
      blood_sugars.discard_all
      business_identifiers.discard_all
      observations.discard_all
      encounters.discard_all
      medical_history&.discard
      phone_numbers.discard_all
      prescription_drugs.discard_all
      teleconsultations.discard_all
      discard
    end
  end
end
