class FacilityDistrict
  attr_reader :name, :scope

  alias_method :id, :name
  alias_method :to_param, :name

  def initialize(name:, scope: Facility.all)
    @name = name
    @scope = scope
  end

  def facilities
    scope.where(district: name)
  end

  def child_region_type
    "facility"
  end

  alias_method :children, :facilities

  # FacilityDistrict always returns child facilities for reports
  def reportable_children
    children
  end

  def organization
    facility_group_ids = facilities.pluck(:facility_group_id).uniq
    organization_ids = FacilityGroup.where(id: facility_group_ids).pluck(:organization_id).uniq
    Organization.where(id: organization_ids).first
  end

  def dashboard_analytics(period:, prev_periods:, include_current_period: true)
    DistrictAnalyticsQuery.new(self, period, prev_periods, include_current_period: include_current_period).call
  end

  def cohort_analytics(period:, prev_periods:)
    CohortAnalyticsQuery.new(self, period: period, prev_periods: prev_periods).call
  end

  def registered_hypertension_patients
    Patient.with_hypertension.where(registration_facility: facilities)
  end

  def registered_diabetes_patients
    Patient.with_diabetes.where(registration_facility: facilities)
  end

  def registered_patients
    Patient.where(registration_facility: facilities)
  end

  def assigned_patients
    Patient.where(assigned_facility: facilities)
  end

  def model_name
    "FacilityDistrict"
  end

  def updated_at
    facilities.maximum(:updated_at) || Time.current.beginning_of_day
  end

  def region
    self
  end

  def cache_key
    ["facility_districts", id].join("/")
  end

  def slug
    name.parameterize
  end

  def cache_version
    updated_at.utc.to_s(:usec)
  end

  # For regions compatibility
  def source
    self
  end

  # For regions compatibility
  def region_type
    "facility_district"
  end

  # For regions compatibility
  def facility_region?
    false
  end

  # For regions compatibility
  def district_region?
    true
  end
end
