class FacilityGroup < ApplicationRecord
  extend FriendlyId
  extend RegionSource
  default_scope -> { kept }

  belongs_to :organization
  belongs_to :protocol

  has_many :facilities, dependent: :nullify
  has_many :users, through: :facilities
  has_many :patients, through: :facilities, source: :registered_patients
  has_many :assigned_patients, through: :facilities, source: :assigned_patients
  has_many :blood_pressures, through: :facilities
  has_many :blood_sugars, through: :facilities
  has_many :encounters, through: :facilities
  has_many :prescription_drugs, through: :facilities
  has_many :appointments, through: :facilities
  has_many :teleconsultations, through: :facilities
  has_many :medical_histories, through: :patients
  has_many :communications, through: :appointments

  alias_method :registered_patients, :patients

  validates :name, presence: true
  validates :organization, presence: true

  friendly_id :name, use: :slugged

  auto_strip_attributes :name, squish: true, upcase_first: true
  attribute :enable_diabetes_management, :boolean

  # FacilityGroups don't actually have a state
  # This virtual attr exists simply to simulate the State -> FG/District hierarchy for Regions.
  attr_writer :state
  validates :state, presence: true, if: -> { Flipper.enabled?(:regions_prep) }

  attr_accessor :new_block_names
  attr_accessor :remove_block_ids

  def state
    @state || region&.state_region&.name
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
      reparent_to: state_region,
      region_type: Region.region_types[:district]
    )
  end

  def update_region
    region.reparent_to = state_region
    region.name = name
    region.save!
  end

  def state_region
    organization.region.state_regions.find_by(name: state)
  end

  private :make_region, :update_region, :state_region
  # ----------------

  def registered_hypertension_patients
    Patient.with_hypertension.where(registration_facility: facilities)
  end

  def toggle_diabetes_management
    if enable_diabetes_management
      set_diabetes_management(true)
    elsif diabetes_enabled?
      set_diabetes_management(false)
    else
      true
    end
  end

  def diabetes_enabled?
    facilities.where(enable_diabetes_management: false).count.zero?
  end

  def create_state_region!
    return unless Flipper.enabled?(:regions_prep)
    return if state_region || state.blank?

    Region.state_regions.create!(name: state, reparent_to: organization.region)
  end

  def update_block_regions!
    create_block_regions!
    remove_block_regions!
  end

  def create_block_regions!
    return unless Flipper.enabled?(:regions_prep)
    return if new_block_names.blank?

    new_block_names.map { |name|
      Region.block_regions.create!(name: name, reparent_to: region)
    }
  end

  def remove_block_regions!
    return unless Flipper.enabled?(:regions_prep)
    return if remove_block_ids.blank?

    remove_block_ids.map { |id|
      next unless Region.find(id)
      next unless Region.find(id).children.empty?

      Region.destroy(id)
    }
  end

  def discardable?
    facilities.none? && patients.none? && blood_pressures.none? && blood_sugars.none? && appointments.none?
  end

  def dashboard_analytics(period:, prev_periods:, include_current_period: true)
    query = DistrictAnalyticsQuery.new(self, period, prev_periods, include_current_period: include_current_period)
    query.call
  end

  def cohort_analytics(period:, prev_periods:)
    query = CohortAnalyticsQuery.new(self, period: period, prev_periods: prev_periods)
    query.call
  end

  def syncable_patients
    registered_patients.with_discarded
  end

  private

  def set_diabetes_management(value)
    facilities.update(enable_diabetes_management: value).map(&:valid?).all?
  end
end
