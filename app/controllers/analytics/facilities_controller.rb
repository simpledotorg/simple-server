class Analytics::FacilitiesController < AnalyticsController
  before_action :set_facility

  def show
    @analytics = @facility.dashboard_analytics
  end

  private

  def set_facility
    facility_id = params[:id] || params[:facility_id]
    @facility = Facility.friendly.find(facility_id)
    authorize(@facility)
  end
end

