class Analytics::FacilitiesController < AnalyticsController
  before_action :set_facility
  before_action :set_facility_group
  before_action :set_organization
  before_action :set_cache_key

  def show
    @facility_analytics = @facility.patient_set_analytics(@from_time, @to_time)
    @user_analytics = user_analytics
  end

  def graphics
    @current_month = Date.today.at_beginning_of_month.to_date
    @facility_analytics = @facility.patient_set_analytics(@from_time, @to_time)
  end

  private

  def set_facility
    facility_id = params[:id] || params[:facility_id]
    @facility = Facility.friendly.find(facility_id)
    authorize(@facility)
  end

  def set_facility_group
    @facility_group = @facility.facility_group
  end

  def set_organization
    @organization = @facility.organization
  end

  def set_cache_key
    @cache_key = [
      "analytics/facilities",
      @facility.slug,
      @from_time.strftime("%Y-%m-%d"),
      @to_time.strftime("%Y-%m-%d")
    ]
  end

  def users_for_facility
    User.joins(:blood_pressures).where('blood_pressures.facility_id = ?', @facility.id).order(:full_name).distinct
  end

  def user_analytics
    users_for_facility.map { |user| [user, Analytics::UserAnalytics.new(user, @facility)] }.to_h
  end
end

