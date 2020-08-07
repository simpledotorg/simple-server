class Reports::RegionsController < AdminController
  layout "application"
  skip_after_action :verify_policy_scoped
  before_action :set_force_cache
  before_action :set_selected_date, except: :index
  before_action :find_region, except: :index
  around_action :set_time_zone

  def index
    authorize(:dashboard, :show?)

    @organizations = policy_scope([:cohort_report, Organization]).order(:name)
  end

  def show
    authorize(:dashboard, :show?)

    @data = RegionReportService.new(region: @region,
                                    period: @period,
                                    current_user: current_admin).call

    if @region.is_a?(FacilityGroup)
      @data_for_facility = @region.facilities.each_with_object({}) { |facility, hsh|
        hsh[facility.name] = RegionReportService.new(region: facility,
                                                     period: @period,
                                                     current_user: current_admin).call
      }
    end

    @controlled_patients = @data[:controlled_patients]
    @registrations = @data[:cumulative_registrations]
    @quarterly_registrations = @data[:quarterly_registrations]
    @top_region_benchmarks = @data[:top_region_benchmarks]
    @last_registration_value = @data[:cumulative_registrations].values&.last || 0
    @new_registrations = @last_registration_value - @registrations.values[-2]
  end

  def details
    authorize(:dashboard, :show?)

    @data = RegionReportService.new(region: @region,
                                    period: @period,
                                    current_user: current_admin).call
    @controlled_patients = @data[:controlled_patients]
    @registrations = @data[:cumulative_registrations]
    @quarterly_registrations = @data[:quarterly_registrations]
    @top_region_benchmarks = @data[:top_region_benchmarks]
    @last_registration_value = @data[:cumulative_registrations].values&.last || 0
  end

  def cohort
    authorize(:dashboard, :show?)

    @data = RegionReportService.new(region: @region,
                                    period: @period,
                                    current_user: current_admin).call
    @controlled_patients = @data[:controlled_patients]
    @registrations = @data[:cumulative_registrations]
    @quarterly_registrations = @data[:quarterly_registrations]
    @top_region_benchmarks = @data[:top_region_benchmarks]
    @last_registration_value = @data[:cumulative_registrations].values&.last || 0
  end

  private

  def set_selected_date
    period_params = facility_params[:period].presence || {type: :month, value: Date.current.last_month.beginning_of_month}
    # TODO this will all go away, no need for building Period from the params
    @period = if period_params[:type] == "quarter"
      Period.new(type: period_params[:type], value: Quarter.parse(period_params[:value]))
    else
      Period.new(type: period_params[:type], value: period_params[:value].to_date)
    end
    @selected_date = @period.value
  end

  def set_force_cache
    RequestStore.store[:force_cache] = true if force_cache?
  end

  def find_region
    region_class, slug = facility_params[:id].split("-", 2)
    unless region_class.in?(["facility_group", "facility"])
      raise ActiveRecord::RecordNotFound
    end
    klass = region_class.classify.constantize
    @region = klass.find_by!(slug: slug)
  end

  def facility_params
    params.permit(:selected_date, :id, :force_cache, {period: [:type, :value]}, :report_scope)
  end

  def force_cache?
    facility_params[:force_cache].present?
  end

  def set_time_zone
    time_zone = Rails.application.config.country[:time_zone] || DEFAULT_ANALYTICS_TIME_ZONE

    Groupdate.time_zone = time_zone

    Time.use_zone(time_zone) { yield }
    Groupdate.time_zone = "UTC"
  end
end
