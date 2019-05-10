class Analytics::DistrictsController < AnalyticsController
  before_action :set_organization
  before_action :set_district
  before_action :set_facilities
  before_action :set_state

  def show
    @days_previous = 20
    @months_previous = 8

    @district_analytics = district_analytics(@from_time, @to_time)
    @facility_analytics = facility_analytics(@from_time, @to_time)
  end

  def graphics
    @current_month = Date.today.at_beginning_of_month.to_date
    @district_analytics = @district.patient_set_analytics(@from_time, @to_time)
  end

  private

  def set_district
    district_id = params[:id] || params[:district_id]
    @district = District.new(district_id, @organization)
    authorize(@district)
  end

  def set_organization
    @district.organization = Organization.find(params[:organization_id])
  end

  def set_facilities
    facilities_by_district = policy_scope(@organization.facility_groups).flat_map(&:facilities).group_by(&:district).sort.to_h
    @district.facilities = facilities_by_district[@district.id].sort_by(&:name)
  end

  def set_state
    state = @district.facilities.first.state.capitalize
    @district.state = state
  end

  def district_analytics(from_time, to_time)
    @district.patient_set_analytics(from_time, to_time)
  end

  def facility_analytics(from_time, to_time)
    @district.facilities
      .map { |facility| [facility, facility.patient_set_analytics(from_time, to_time)] }
      .to_h
  end
end
