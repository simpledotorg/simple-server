class Analytics::FacilityGroupsController < AnalyticsController
  before_action :set_facility_group
  before_action :set_organization
  before_action :set_facilities
  before_action :set_cache_key

  def show
    @days_previous = 20
    @months_previous = 8

    @facility_group_analytics = facility_group_analytics(@from_time, @to_time)
    @facility_analytics = facility_analytics(@from_time, @to_time)
  end

  def graphics
    @current_month = Date.today.at_beginning_of_month.to_date
    @facility_group_analytics = @facility_group.patient_set_analytics(@from_time, @to_time)
  end

  private

  def set_facility_group
    facility_group_id = params[:id] || params[:facility_group_id]
    @facility_group = FacilityGroup.friendly.find(facility_group_id)
    authorize(@facility_group)
  end

  def set_organization
    @organization = @facility_group.organization
  end

  def set_facilities
    @facilities = policy_scope(@facility_group.facilities).order(:name)
  end

  def set_cache_key
    @cache_key = [
      "analytics/facility_groups",
      @facility_group.id,
      @from_time.strftime("%Y-%m-%d"),
      @to_time.strftime("%Y-%m-%d")
    ]
  end

  def facility_group_analytics(from_time, to_time)
    @facility_group.patient_set_analytics(from_time, to_time)
  end

  def facility_analytics(from_time, to_time)
    @facilities
      .map { |facility| [facility, facility.patient_set_analytics(from_time, to_time)] }
      .to_h
  end
end
