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

  def organization
    facility_group_ids = facilities.pluck(:facility_group_id).uniq
    organization_ids = FacilityGroup.where(id: facility_group_ids).pluck(:organization_id).uniq
    Organization.where(id: organization_ids).first
  end

  def dashboard_analytics(period:, prev_periods:)
    query = DistrictAnalyticsQuery.new(name, facilities, period, prev_periods, include_current_period: true)
    query.call
  end

  def cohort_analytics(period:, prev_periods:)
    query = CohortAnalyticsQuery.new(self, period: period, prev_periods: prev_periods)
    query.call
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
end
