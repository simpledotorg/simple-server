class Analytics::DistrictsController < AnalyticsController
  before_action :set_district
  before_action :set_organization
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
    district_name = params[:id] || params[:district_id]
    @organization_district = OrganizationDistrict.new(district_name)
    authorize(@organization_district)
  end

  def set_organization
    @organization_district.organization = Organization.find(params[:organization_id])
  end

  def set_facilities
    facilities_by_district = policy_scope(@organization_district.organization.facilities).group_by(&:district).sort.to_h
    @organization_district.facilities = facilities_by_district[@organization_district.district_name].sort_by(&:name)
  end

  def district_analytics(from_time, to_time)
    @organization_district.patient_set_analytics(from_time, to_time)
  end

  def facility_analytics(from_time, to_time)
    @organization_district.facilities
      .map { |facility| [facility, facility.patient_set_analytics(from_time, to_time)] }
      .to_h
  end
end
