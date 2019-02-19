class Analytics::FacilityGroupsController < AnalyticsController
  def show
    skip_authorization

    @facility_group = FacilityGroup.friendly.find(params[:id])
    @organization = @facility_group.organization

    Groupdate.time_zone = "New Delhi"

    @days_previous = 20
    @months_previous = 8

    @from_time = 90.days.ago
    @to_time = Date.today

    @facilities = @facility_group.facilities
    @facility_group_analytics = Analytics::FacilityGroupAnalytics.new(
      @facility_group,
      days_previous: @days_previous,
      months_previous: @months_previous,
      from_time: @from_time,
      to_time: @to_time
    )

    @facility_analytics = @facilities.map do |facility|
      [facility, Analytics::FacilityAnalytics.new(facility, from_time: @from_time, to_time: @to_time)]
    end.to_h

    # Reset when done
    Groupdate.time_zone = "UTC"
  end

  def graphics
    skip_authorization

    @facility_group = FacilityGroup.friendly.find(params[:facility_group_id])
    @organization = @facility_group.organization


    Groupdate.time_zone = "New Delhi"

    @months_previous = 4

    @current_month = Date.today.at_beginning_of_month.to_date
    @from_time = @current_month
    @to_time = @current_month.at_end_of_month

    @facilities = @facility_group.facilities
    @facility_group_analytics = Analytics::FacilityGroupAnalytics.new(
      @facility_group,
      from_time: @from_time,
      to_time: @to_time,
      months_previous: @months_previous
    )

    # Reset when done
    Groupdate.time_zone = "UTC"
  end

end