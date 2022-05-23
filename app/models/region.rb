class Region < ApplicationRecord
  include Flipperable

  MAX_LABEL_LENGTH = 255

  delegate :cache, to: Rails
  ltree :path
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :path, presence: true, uniqueness: true
  validates :region_type, presence: true

  belongs_to :source, polymorphic: true, optional: true
  auto_strip_attributes :name, squish: true, upcase_first: true

  has_many :drug_stocks
  has_one :estimated_population, -> { where(diagnosis: EstimatedPopulation.diagnoses[:HTN]) }, autosave: true, inverse_of: :region
  has_one :estimated_diabetes_population, -> { where(diagnosis: EstimatedPopulation.diagnoses[:DM]) },
    autosave: true, class_name: "EstimatedPopulation", inverse_of: :diabetes_region

  after_discard do
    estimated_population&.discard
  end

  # To set a new path for a Region, assign the parent region via `reparent_to`, and the before_validation
  # callback will assign the new path.
  attr_accessor :reparent_to
  attr_accessor :parent_path
  before_validation :initialize_path, if: :reparent_to
  before_validation :_set_path_for_seeds, if: :parent_path
  before_discard :remove_path

  REGION_TYPES = %w[root organization state district block facility].freeze
  enum region_type: REGION_TYPES.zip(REGION_TYPES).to_h, _suffix: "regions"

  REGION_TYPES.each do |type|
    # Our enum adds a pluralized suffix, which is nice for scopes, but weird for the question methods
    # with individual objects. So we define our own question methods here for a nicer API.
    define_method("#{type}_region?") do
      region_type == type
    end
    # Don't leave around the old, auto generated methods to avoid confusion
    undef_method "#{type}_regions?"
  end

  def child_region_type
    current_index = REGION_TYPES.find_index { |type| type == region_type }
    REGION_TYPES[current_index + 1]
  end

  def reportable_region?
    return true if CountryConfig.current[:extended_region_reports]
    region_type.in?(["district", "facility"])
  end

  def reportable_children
    return children if CountryConfig.current[:extended_region_reports]
    legacy_children
  end

  # Legacy children are used for countries where we _don't_ want to display every level of the region hiearchy,
  # like in Bangladesh for example.
  def legacy_children
    case region_type
    when "organization" then district_regions
    when "district" then facility_regions
    when "facility" then []
    else raise ArgumentError, "unsupported region_type #{region_type} for legacy_children"
    end
  end

  def accessible_children(admin, region_type: child_region_type, access_level: :any)
    auth_method = "accessible_#{region_type}_regions"
    region_method = "#{region_type}_regions"
    superset = public_send(region_method)
    authorized_set = admin.public_send(auth_method, access_level)
    superset & authorized_set
  end

  def organization
    organization_region.source
  end

  def cached_ancestors
    cache.fetch("#{cache_key}/ancestors", version: "#{cache_version}/#{path}/v4") do
      ancestors.order(:path).all.to_a
    end
  end

  def self.root
    Region.find_by(region_type: :root)
  end

  def slug_candidates
    [
      :name,
      [:name, :region_type],
      [:name, :region_type, :short_uuid]
    ]
  end

  def short_uuid
    SecureRandom.uuid[0..7]
  end

  def registered_hypertension_patients
    Patient.with_hypertension.where(registration_facility: facilities)
  end

  def registered_diabetes_patients
    Patient.with_diabetes.where(registration_facility: facilities)
  end

  def facilities
    if facility_region?
      Facility.where(id: source_id)
    else
      source_ids = facility_regions.pluck(:source_id)
      Facility.where(id: source_ids)
    end
  end

  def facility_ids
    facilities.pluck(:id)
  end

  def cohort_analytics(period:, prev_periods:)
    CohortAnalyticsQuery.new(self, period: period, prev_periods: prev_periods).call
  end

  def dashboard_analytics(period:, prev_periods:, include_current_period: true)
    if facility_region?
      FacilityAnalyticsQuery.new(self, period, prev_periods, include_current_period: include_current_period).call
    else
      DistrictAnalyticsQuery.new(self, period, prev_periods, include_current_period: include_current_period).call
    end
  end

  # Keep the state population in sync with districts -- this is primarily used from FacilityGroupRegionSync
  def recalculate_state_population!
    new_total = district_regions.includes(:estimated_population).sum(:population)
    population = estimated_population || build_estimated_population
    population.update! population: new_total
  end

  def recalculate_state_diabetes_population!
    new_total = district_regions.includes(:estimated_diabetes_population).sum(:population)
    population = estimated_diabetes_population || build_estimated_diabetes_population
    population.update! population: new_total
  end

  def syncable_patients
    case region_type
      when "block"
        registered_patients.with_discarded
          .select(:id, :registration_facility_id)
          .or(assigned_patients.with_discarded.select(:id, :registration_facility_id))
          .union(appointed_patients.with_discarded.select(:id, :registration_facility_id))
      else
        registered_patients.with_discarded
    end
  end

  def registered_patients
    Patient.where(registration_facility: facility_regions.pluck(:source_id))
  end

  def assigned_patients
    Patient.where(assigned_facility: facility_regions.pluck(:source_id))
  end

  def appointed_patients
    Patient.joins(:appointments).where(appointments: {facility: facility_regions.pluck(:source_id)})
  end

  def diabetes_management_enabled?
    facilities.where(enable_diabetes_management: true).exists?
  end

  REGION_TYPES.reject { |t| t == "root" }.map do |region_type|
    # Generates belongs_to type of methods to fetch a region's ancestor
    # e.g. facility.organization
    ancestor_method = "#{region_type}_region"
    define_method(ancestor_method) do
      if self_and_descendant_types(region_type).include?(self.region_type)
        self_and_ancestors.find_by(region_type: region_type)
      else
        raise NoMethodError, "undefined method #{region_type}_region for region '#{name}' of type #{self.region_type}"
      end
    end

    # Generates has_many type of methods to fetch a region's descendants
    # e.g. organization.facility_regions
    descendant_method = "#{region_type}_regions"
    define_method(descendant_method) do
      if self_and_ancestor_types(region_type).include?(self.region_type)
        self_and_descendants.where(region_type: region_type)
      else
        raise NoMethodError, "undefined method #{region_type.pluralize}_regions for region '#{name}' of type #{self.region_type}"
      end
    end
  end

  def localized_region_type
    I18n.t("region_type.#{region_type}")
  end

  def localized_child_region_type
    return nil if child_region_type.nil?
    I18n.t("region_type.#{child_region_type}")
  end

  def log_payload
    attrs = attributes.slice("name", "slug", "path")
    attrs["id"] = id.presence
    attrs["region_type"] = region_type
    attrs["errors"] = errors.full_messages.join(",") if errors.any?
    attrs.symbolize_keys
  end

  def region
    self
  end

  def cache_key
    [model_name.cache_key, region_type, id].join("/")
  end

  def cache_version
    updated_at.utc.to_s(:usec)
  end

  def supports_htn_population_coverage
    return true if region.district_region? || region.state_region?
  end

  def supports_diabetes_population_coverage
    return true if CountryConfig.current[:enabled_diabetes_population_coverage] && (region.district_region? || region.state_region?)
  end

  private

  def _set_path_for_seeds
    self.path = "#{parent_path}.#{path_label}"
  end

  def initialize_path
    # logger.info(class: self.class.name, msg: "got reparent_to: #{reparent_to.name}, going to initialize new path")
    self.path = if reparent_to.path.present?
      "#{reparent_to.path}.#{path_label}"
    else
      path_label
    end

    self.reparent_to = nil
  end

  def remove_path
    self.path = nil
  end

  def ancestor_types(region_type)
    REGION_TYPES.split(region_type).first
  end

  def descendant_types(region_type)
    REGION_TYPES.split(region_type).second
  end

  def self_and_ancestor_types(region_type)
    ancestor_types(region_type) + [region_type]
  end

  def self_and_descendant_types(region_type)
    [region_type] + descendant_types(region_type)
  end

  # A label is a sequence of alphanumeric characters and underscores.
  # (In C locale the characters A-Za-z0-9_ are allowed).
  # Labels must be less than 256 bytes long.
  def path_label
    set_slug unless slug
    slug.gsub(/\W/, "_").slice(0, MAX_LABEL_LENGTH)
  end
end
