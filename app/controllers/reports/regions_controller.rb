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

    @data = Reports::RegionService.new(region: @region,
                                       period: @period).call
    @controlled_patients = @data[:controlled_patients]
    @quarterly_registrations = @data[:quarterly_registrations]
    @last_registration_value = @data[:cumulative_registrations].values&.last || 0
    @new_registrations = @last_registration_value - @data[:cumulative_registrations].values[-2]
    @adjusted_registration_date = @data[:adjusted_registrations].keys[-4]
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

  def set_selected_date
    period_params = facility_params[:period]
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
    slug = facility_params[:id]
    klass = region_class.classify.constantize
    @region = klass.find_by!(slug: slug)
  end

  def region_class
    @region_class ||= case facility_params[:report_scope]
    when "district"
      "facility_group"
    when "facility"
      "facility"
    else
      raise ActiveRecord::RecordNotFound, "unknown report scope #{facility_params[:report_scope]}"
    end
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
