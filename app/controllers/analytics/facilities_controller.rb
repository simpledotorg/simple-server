class Analytics::FacilitiesController < AnalyticsController
  def show
    skip_authorization
    @facility = Facility.friendly.find(params[:id])
    @facility_group = @facility.facility_group
    @organization = @facility_group.organization

    @facility_analytics = Analytics::FacilityAnalytics.new(@facility, from_time: 90.days.ago, to_time: Date.today)
    @user_analytics = @facility.users.map { |user| [user, Analytics::UserAnalytics.new(user)] }.to_h
  end

  def graphics
    skip_authorization

    @facility = Facility.friendly.find(params[:facility_id])
    @facility_group = @facility.facility_group
    @organization = @facility_group.organization

    @current_month = Date.today.at_beginning_of_month.to_date

    @facility_analytics = Analytics::FacilityAnalytics.new(@facility, months_previous: 6)
  end
end