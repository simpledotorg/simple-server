class Reports::RegionsController < AdminController
  layout "application"
  skip_after_action :verify_policy_scoped
  before_action :set_force_cache
  before_action :set_period, except: :index
  before_action :find_region, except: :index
  around_action :set_time_zone

  def index
    authorize(:dashboard, :show?)

    @organizations = policy_scope([:cohort_report, Organization]).order(:name)
  end

  def show
    authorize(:dashboard, :show?)

    @data = Reports::RegionService.new(region: @region,
                                       period: @period).call
    @controlled_patients = @data[:controlled_patients]
    @quarterly_registrations = @data[:quarterly_registrations]
    @last_registration_value = @data[:cumulative_registrations].values&.last || 0
    @new_registrations = @last_registration_value - @data[:cumulative_registrations].values[-2]
    @adjusted_registration_date = @data[:adjusted_registrations].keys[-4]

    if @region.is_a?(FacilityGroup)
      @data_for_facility = @region.facilities.each_with_object({}) { |facility, hsh|
        hsh[facility.name] = Reports::RegionService.new(region: facility,
                                                        period: @period).call
      }
    end
  end

  def details
    authorize(:dashboard, :show?)

    @data = Reports::RegionService.new(region: @region,
                                       period: @period).call
    @controlled_patients = @data[:controlled_patients]
    @registrations = @data[:cumulative_registrations]
    @quarterly_registrations = @data[:quarterly_registrations]
    @last_registration_value = @data[:cumulative_registrations].values&.last || 0
    @adjusted_registration_date = @data[:adjusted_registrations].keys[-4]
  end

  def cohort
    authorize(:dashboard, :show?)

    @data = Reports::RegionService.new(region: @region,
                                       period: @period).call
    @controlled_patients = @data[:controlled_patients]
    @registrations = @data[:cumulative_registrations]
    @quarterly_registrations = @data[:quarterly_registrations]
    @last_registration_value = @data[:cumulative_registrations].values&.last || 0
  end

  private

  def set_period
    period_params = report_params[:period]
    @period = if period_params.present?
      Period.new(period_params)
    else
      Reports::RegionService.default_period
    end
  end

  def set_force_cache
    RequestStore.store[:force_cache] = true if force_cache?
  end

  def find_region
    slug = report_params[:id]
    klass = region_class.classify.constantize
    @region = klass.find_by!(slug: slug)
  end

  def region_class
    @region_class ||= case report_params[:report_scope]
    when "district"
      "facility_group"
    when "facility"
      "facility"
    else
      raise ActiveRecord::RecordNotFound, "unknown report scope #{report_params[:report_scope]}"
    end
  end

  def report_params
    params.permit(:id, :force_cache, :report_scope, {period: [:type, :value]})
  end

  def force_cache?
    report_params[:force_cache].present?
  end

  def set_time_zone
    time_zone = Rails.application.config.country[:time_zone] || DEFAULT_ANALYTICS_TIME_ZONE

    Groupdate.time_zone = time_zone

    Time.use_zone(time_zone) { yield }
    Groupdate.time_zone = "UTC"
  end
end
