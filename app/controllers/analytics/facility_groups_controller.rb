class Analytics::FacilityGroupsController < AnalyticsController
  def show
    skip_authorization

    @facility_group = FacilityGroup.friendly.find(params[:id])
    @organization = @facility_group.organization

    Groupdate.time_zone = "New Delhi"

    @days_previous = 20
    @months_previous = 8

    @facilities = @facility_group.facilities
    @facility_group_analytics = Analytics::FacilityGroupDashboard.new(
      @facility_group,
      days_previous: @days_previous,
      months_previous: @months_previous
    )

    # Reset when done
    Groupdate.time_zone = "UTC"
  end

  def graphics
    skip_authorization
  end
end