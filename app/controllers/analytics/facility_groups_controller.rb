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

    @facility_analytics = @facilities.map { |facility| [facility, Analytics::FacilityAnalytics.new(facility)] }.to_h

    # Reset when done
    Groupdate.time_zone = "UTC"
  end

  def graphics
    skip_authorization

    @facility_group = FacilityGroup.friendly.find(params[:facility_group_id])
    @organization = @facility_group.organization


    Groupdate.time_zone = "New Delhi"

    @months_previous = 4

    @range = (1.month.ago..Date.today)

    @facilities = @facility_group.facilities
    @facility_group_graphics = Analytics::FacilityGroupGraphics.new(
      @facility_group,
      months_previous: @months_previous
    )

    # Reset when done
    Groupdate.time_zone = "UTC"
  end
end