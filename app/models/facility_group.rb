class FacilityGroup < ApplicationRecord
  extend FriendlyId
  extend RegionSource
  default_scope -> { kept }

  belongs_to :organization
  belongs_to :protocol

  has_many :facilities, dependent: :nullify
  has_many :users, through: :facilities

  has_many :patients, through: :facilities, source: :registered_patients
  alias_method :registered_patients, :patients
  has_many :assigned_patients, through: :facilities, source: :assigned_patients
  has_many :blood_pressures, through: :facilities
  has_many :blood_sugars, through: :facilities
  has_many :encounters, through: :facilities
  has_many :prescription_drugs, through: :facilities
  has_many :appointments, through: :facilities
  has_many :teleconsultations, through: :facilities

  has_many :medical_histories, through: :patients
  has_many :communications, through: :appointments

  validates :name, presence: true
  validates :organization, presence: true
  validates :state, presence: true, if: -> { Flipper.enabled?(:region_level_sync) }

  friendly_id :name, use: :slugged

  auto_strip_attributes :name, squish: true, upcase_first: true
  attribute :enable_diabetes_management, :boolean
  attr_writer :state

  def state
    @state || region&.state&.name
  end

  attr_accessor :blocks_added
  attr_accessor :blocks_deleted

  after_create :create_region, if: -> { Flipper.enabled?(:region_level_sync) }
  after_update :update_region, if: -> { Flipper.enabled?(:region_level_sync) }
  after_save :update_blocks

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

  def report_on_patients
    Patient.where(registration_facility: facilities)
  end

  def diabetes_enabled?
    facilities.where(enable_diabetes_management: false).count.zero?
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

  private

  def set_diabetes_management(value)
    facilities.update(enable_diabetes_management: value).map(&:valid?).all?
  end

  def create_region
    Region.create!(
      name: name,
      source: self,
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
    Region.state.find_by_name(state) || Region.create(name: state,
                                                      region_type: Region.region_types[:state],
                                                      reparent_to: organization.region)
  end

  def update_blocks
    create_blocks if blocks_added.present?
    delete_blocks if blocks_deleted.present?
  end

  def create_blocks
    blocks_added.map do |block|
      Region.create(
        name: block,
        region_type: Region.region_types[:block],
        reparent_to: region
      )
    end
  end

  def delete_blocks
    blocks_deleted.map do |id|
      Region.destroy(id) if Region.find(id) && Region.find(id).children.empty?
    end
  end
end
