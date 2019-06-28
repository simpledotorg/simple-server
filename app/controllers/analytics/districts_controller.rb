class Analytics::DistrictsController < AnalyticsController
  before_action :set_organization_district

  def show
    @analytics = @organization_district.dashboard_analytics
  end

  private

  def set_organization_district
    district_name = params[:id] || params[:district_id]
    organization = Organization.find_by(id: params[:organization_id])
    @organization_district = OrganizationDistrict.new(district_name, organization)
    authorize(@organization_district)
  end
end
