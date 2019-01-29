class Analytics::FacilitiesController < AnalyticsController
  def show
    skip_authorization
    @facility = Facility.friendly.find(params[:id])
    @facility_group = @facility.facility_group
    @organization = @facility_group.organization
  end
end