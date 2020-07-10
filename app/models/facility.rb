require "roo"

class Facility < ApplicationRecord
  include Mergeable
  include QuarterHelper
  include PgSearch::Model
  include LiberalEnum
  extend FriendlyId

  before_save :clear_isd_code, unless: -> { teleconsultation_phone_number.present? }

  attribute :import, :boolean, default: false
  attribute :organization_name, :string
  attribute :facility_group_name, :string

  belongs_to :facility_group, optional: true

  has_many :phone_number_authentications, foreign_key: "registration_facility_id"
  has_many :users, through: :phone_number_authentications

  has_many :encounters
  has_many :blood_pressures, through: :encounters, source: :blood_pressures
  has_many :blood_sugars, through: :encounters, source: :blood_sugars
  has_many :patients, -> { distinct }, through: :encounters
  has_many :prescription_drugs
  has_many :appointments

  has_many :registered_patients,
    class_name: "Patient",
    foreign_key: "registration_facility_id"
  has_many :registered_diabetes_patients,
    -> { with_diabetes },
    class_name: "Patient",
    foreign_key: "registration_facility_id"
  has_many :registered_hypertension_patients,
    -> { with_hypertension },
    class_name: "Patient",
    foreign_key: "registration_facility_id"

  pg_search_scope :search_by_name, against: {name: "A", slug: "B"}, using: {tsearch: {prefix: true, any_word: true}}

  enum facility_size: {
    community: "community",
    small: "small",
    medium: "medium",
    large: "large"
  }

  liberal_enum :facility_size

  auto_strip_attributes :name, squish: true, upcase_first: true
  auto_strip_attributes :district, squish: true, upcase_first: true

  with_options if: :import do |facility|
    facility.validates :organization_name, presence: true
    facility.validates :facility_group_name, presence: true
    facility.validate :facility_name_presence
    facility.validate :organization_exists
    facility.validate :facility_group_exists
    facility.validate :facility_is_unique
  end

  with_options unless: :import do |facility|
    facility.validates :name, presence: true
  end

  validates :district, presence: true
  validates :state, presence: true
  validates :country, presence: true
  validates :pin, numericality: true, allow_blank: true

  validates :facility_size, inclusion: {in: facility_sizes.values,
                                        message: "not in #{facility_sizes.values.join(", ")}",
                                        allow_blank: true}
  validates :enable_teleconsultation, inclusion: {in: [true, false]}
  validates :enable_diabetes_management, inclusion: {in: [true, false]}
  validate :teleconsultation_phone_numbers_valid?, if: :teleconsultation_enabled?

  delegate :protocol, to: :facility_group, allow_nil: true
  delegate :organization, to: :facility_group, allow_nil: true
  delegate :follow_ups_by_period, to: :patients, prefix: :patient
  delegate :diabetes_follow_ups_by_period, to: :patients
  delegate :hypertension_follow_ups_by_period, to: :patients

  friendly_id :name, use: :slugged

  # For compatibility w/ parent FacilityGroups
  def facilities
    [self]
  end

  def cohort_analytics(period, prev_periods)
    query = CohortAnalyticsQuery.new(registered_hypertension_patients)
    query.patient_counts_by_period(period, prev_periods)
  end

  def dashboard_analytics(period: :month, prev_periods: 3, include_current_period: false)
    query = FacilityAnalyticsQuery.new(self,
      period,
      prev_periods,
      include_current_period: include_current_period)

    results = [
      query.registered_patients_by_period,
      query.total_registered_patients,
      query.follow_up_patients_by_period
    ].compact

    return {} if results.blank?
    results.inject(&:deep_merge)
  end

  CSV_IMPORT_COLUMNS =
    {organization_name: "organization",
     facility_group_name: "facility_group",
     name: "facility_name",
     facility_type: "facility_type",
     street_address: "street_address (optional)",
     village_or_colony: "village_or_colony (optional)",
     zone: "zone_or_block (optional)",
     district: "district",
     state: "state",
     country: "country",
     pin: "pin (optional)",
     latitude: "latitude (optional)",
     longitude: "longitude (optional)",
     facility_size: "size (optional)",
     enable_diabetes_management: "enable_diabetes_management (true/false)",
     enable_teleconsultation: "enable_teleconsultation (true/false)",
     teleconsultation_phone_number: "teleconsultation_phone_number",
     teleconsultation_isd_code: "teleconsultation_isd_code"}

  def self.parse_facilities(file_contents)
    facilities = []
    CSV.parse(file_contents, headers: true, converters: :strip_whitespace) do |row|
      facility = CSV_IMPORT_COLUMNS.map { |attribute, column_name| [attribute, row[column_name]] }.to_h
      next if facility.values.all?(&:blank?)

      facilities << facility.merge(enable_diabetes_management: facility[:enable_diabetes] || false,
                                   enable_teleconsultation: facility[:enable_teleconsultation] || false,
                                   import: true)
    end
    facilities
  end

  def organization_exists
    organization = Organization.find_by(name: organization_name)
    errors.add(:organization, "doesn't exist") if organization_name.present? && organization.blank?
  end

  def facility_group_exists
    organization = Organization.find_by(name: organization_name)
    if organization.present?
      facility_group = FacilityGroup.find_by(name: facility_group_name,
                                             organization_id: organization.id)
    end
    if organization.present? && facility_group_name.present? && facility_group.blank?
      errors.add(:facility_group, "doesn't exist for the organization")
    end
  end

  def facility_is_unique
    organization = Organization.find_by(name: organization_name)
    if organization.present?
      facility_group = FacilityGroup.find_by(name: facility_group_name,
                                             organization_id: organization.id)
    end
    facility = Facility.find_by(name: name, facility_group: facility_group.id) if facility_group.present?
    errors.add(:facility, "already exists") if organization.present? && facility_group.present? && facility.present?
  end

  def facility_name_presence
    if name.blank?
      errors.add(:facility_name, "can't be blank")
    end
  end

  def diabetes_enabled?
    enable_diabetes_management.present?
  end

  def teleconsultation_enabled?
    enable_teleconsultation.present?
  end

  def teleconsultation_phone_number_with_isd
    teleconsultation_phone_number = teleconsultation_phone_numbers.first
    return if teleconsultation_phone_number.blank?

    Phonelib.parse(teleconsultation_phone_number.isd_code + teleconsultation_phone_number.phone_number).full_e164
  end

  def teleconsultation_phone_numbers_with_isd
    teleconsultation_phone_numbers.map do |phone_number|
      {phone_number: Phonelib.parse(phone_number.isd_code + phone_number.phone_number).full_e164}
    end
  end

  CSV::Converters[:strip_whitespace] = ->(value) {
    begin
      value.strip
    rescue
      value
    end
  }

  def teleconsultation_phone_numbers
    read_attribute(:teleconsultation_phone_numbers).map do |phone_number|
      TeleconsultationPhoneNumber.new(phone_number["isd_code"], phone_number["phone_number"])
    end
  end

  def teleconsultation_phone_numbers_attributes=(numbers)
    phone_numbers = []
    numbers.each do |_index, number|
      number = number.with_indifferent_access
      next if number[:_destroy] == "true" || number[:isd_code].blank? || number[:phone_number].blank?

      phone_numbers << TeleconsultationPhoneNumber.new(number[:isd_code], number[:phone_number])
    end
    write_attribute(:teleconsultation_phone_numbers, phone_numbers)
  end

  def teleconsultation_phone_numbers=(numbers)
    phone_numbers = []
    numbers.each do |number|
      number = number.with_indifferent_access
      next if number[:isd_code].blank? || number[:phone_number].blank?

      phone_numbers << TeleconsultationPhoneNumber.new(number[:isd_code], number[:phone_number])
    end
    write_attribute(:teleconsultation_phone_numbers, phone_numbers)
  end

  def build_teleconsultation_phone_number
    numbers = teleconsultation_phone_numbers.dup
    numbers << TeleconsultationPhoneNumber.new(Rails.application.config.country["sms_country_code"])
    self[:teleconsultation_phone_numbers] = numbers
  end

  TeleconsultationPhoneNumber = Struct.new(:isd_code, :phone_number) {
    def persisted?
      false
    end

    def _destroy
      false
    end
  }

  private

  def clear_isd_code
    self.teleconsultation_isd_code = ""
  end

  def teleconsultation_phone_numbers_valid?
    message = "At least one medical officer must be added to enable teleconsultation, all teleconsultation numbers"\
      " must have a country code and a phone number"
    if teleconsultation_phone_numbers.blank?
      errors.add("teleconsultation_phone_numbers_attributes", message)
      return
    end

    teleconsultation_phone_numbers.each do |mo|
      if mo.isd_code.blank? || mo.phone_number.blank?
        errors.add("teleconsultation_phone_numbers_attributes", message)
        break
      end
    end
  end
end
