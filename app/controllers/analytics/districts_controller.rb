class Analytics::DistrictsController < AnalyticsController
  before_action :set_district
  before_action :set_organization
  before_action :set_facilities

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
    @district = District.new(district_id)
    authorize(@district)
  end

  def set_organization
    @district.organization_id = params[:organization_id]
  end

  def set_facilities
    organization = Organization.find(@district.organization_id)
    facilities_by_district = policy_scope(organization.facility_groups).flat_map(&:facilities).group_by(&:district).sort.to_h
    @facilities = facilities_by_district[@district.id]
    @district.facilities_ids = @facilities&.map(&:id)
  end

  def district_analytics(from_time, to_time)
    @district.patient_set_analytics(from_time, to_time)
  end

  def facility_analytics(from_time, to_time)
    @facilities
      .map { |facility| [facility, facility.patient_set_analytics(from_time, to_time)] }
      .to_h
  end
end
