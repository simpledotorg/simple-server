require "roo"

class Facility < ApplicationRecord
  include Mergeable
  include QuarterHelper
  include PgSearch::Model
  include LiberalEnum

  extend FriendlyId
  extend RegionSource

  friendly_id :name, use: :slugged

  attribute :import, :boolean, default: false
  attribute :organization_name, :string
  attribute :facility_group_name, :string

  belongs_to :facility_group, optional: true

  has_many :phone_number_authentications, foreign_key: "registration_facility_id"
  has_many :users, through: :phone_number_authentications
  has_and_belongs_to_many :teleconsultation_medical_officers,
    -> { distinct },
    class_name: "User",
    association_foreign_key: :user_id,
    join_table: "facilities_teleconsultation_medical_officers"

  has_many :encounters
  has_many :blood_pressures, through: :encounters, source: :blood_pressures
  has_many :blood_sugars, through: :encounters, source: :blood_sugars
  has_many :patients, -> { distinct }, through: :encounters
  has_many :prescription_drugs
  has_many :appointments
  has_many :teleconsultations

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
  has_many :assigned_patients,
    class_name: "Patient",
    foreign_key: "assigned_facility_id"
  has_many :assigned_hypertension_patients,
    -> { with_hypertension },
    class_name: "Patient",
    foreign_key: "assigned_facility_id"

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
  auto_strip_attributes :zone, squish: true, upcase_first: true

  alias_attribute :block, :zone

  validates :name, presence: true
  validates :district, presence: true
  validates :slug, presence: true
  validates :state, presence: true
  validates :country, presence: true
  validates :zone, presence: true, on: :create
  validates :pin, numericality: true, allow_blank: true
  validates :facility_size,
    inclusion: {
      in: facility_sizes.values,
      message: "not in #{facility_sizes.values.join(", ")}",
      allow_blank: true
    }
  validates :enable_teleconsultation, inclusion: {in: [true, false]}
  validates :teleconsultation_medical_officers,
    presence: {
      if: :enable_teleconsultation,
      message: "must be added to enable teleconsultation"
    }
  validates :enable_diabetes_management, inclusion: {in: [true, false]}
  validate :block_allowed, if: -> { Flipper.enabled?(:regions_prep) }

  delegate :protocol, to: :facility_group, allow_nil: true
  delegate :organization, :organization_id, to: :facility_group, allow_nil: true
  delegate :follow_ups_by_period, to: :patients, prefix: :patient

  def self.parse_facilities_from_file(file_contents)
    Csv::FacilitiesParser.parse(file_contents)
  end

  # ----------------
  # Region callbacks
  #
  # * These callbacks are medium-term temporary.
  # * This class and the Region callbacks should ideally be totally superseded by the Region class.
  # * Keep the callbacks simple (avoid branching and optimization), idempotent (if possible) and loud when things break.
  after_create :make_region, if: -> { Flipper.enabled?(:regions_prep) }
  after_update :update_region, if: -> { Flipper.enabled?(:regions_prep) }

  def make_region
    return if region&.persisted?

    create_region!(
      name: name,
      reparent_to: block_region,
      region_type: Region.region_types[:facility]
    )
  end

  def update_region
    region.reparent_to = block_region
    region.name = name
    region.save!
  end

  def block_region
    facility_group.region.block_regions.find_by(name: block)
  end

  private :make_region, :update_region
  # ----------------

  def hypertension_follow_ups_by_period(*args)
    patients
      .hypertension_follow_ups_by_period(*args)
      .where(blood_pressures: {facility: self})
  end

  def diabetes_follow_ups_by_period(*args)
    patients
      .diabetes_follow_ups_by_period(*args)
      .where(blood_sugars: {facility: self})
  end

  # For compatibility w/ parent FacilityGroups
  def facilities
    [self]
  end

  def recent_blood_pressures
    blood_pressures.includes(:patient, :user).order(Arel.sql("DATE(recorded_at) DESC, recorded_at ASC"))
  end

  def cohort_analytics(period:, prev_periods:)
    query = CohortAnalyticsQuery.new(self, period: period, prev_periods: prev_periods)
    query.call
  end

  def dashboard_analytics(period: :month, prev_periods: 3, include_current_period: false)
    query = FacilityAnalyticsQuery.new(self, period, prev_periods, include_current_period: include_current_period)
    query.call
  end

  def diabetes_enabled?
    enable_diabetes_management.present?
  end

  def opd_load_estimated?
    monthly_estimated_opd_load.present?
  end

  def opd_load
    monthly_estimated_opd_load || opd_load_for_facility_size
  end

  def opd_load_for_facility_size
    case facility_size
    when "community" then 450
    when "small" then 1800
    when "medium" then 3000
    when "large" then 7500
    else 450
    end
  end

  def teleconsultation_enabled?
    enable_teleconsultation.present?
  end

  def teleconsultation_phone_number_with_isd
    teleconsultation_phone_numbers_with_isd.first
  end

  def teleconsultation_phone_numbers_with_isd
    teleconsultation_medical_officers.map(&:full_teleconsultation_phone_number)
  end

  def discardable?
    registered_patients.none? && blood_pressures.none? && blood_sugars.none? && appointments.none?
  end

  def block_allowed
    unless facility_group.region.blocks.pluck(:name).include?(block)
      errors.add(:zone, "not present in the facility group")
    end
  end
end
