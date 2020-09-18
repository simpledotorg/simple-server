class Reports::RegionsController < AdminController
  include Pagination
  skip_after_action :verify_policy_scoped
  before_action :set_force_cache
  before_action :set_period, only: [:show, :details, :cohort]
  before_action :set_page, only: [:details]
  before_action :set_per_page, only: [:details]
  before_action :find_region, except: :index
  around_action :set_time_zone

  skip_after_action :verify_authorized, if: -> { current_admin.permissions_v2_enabled? }
  after_action :verify_authorization_attempted, if: -> { current_admin.permissions_v2_enabled? }

  def index
    if current_admin.permissions_v2_enabled?
      authorize_v2 { current_admin.accessible_facilities(:view_reports).any? }
      @organizations = current_admin.accessible_facilities(:view_reports)
        .flat_map(&:organization)
        .uniq
        .compact
        .sort_by(&:name)
    else
      authorize(:dashboard, :show?)
      @organizations = policy_scope([:cohort_report, Organization]).order(:name)
    end
  end

  def show
    if current_admin.permissions_v2_enabled?
      authorize_v2 { current_admin.accessible_facilities(:view_reports).any? }
    else
      authorize(:dashboard, :show?)
    end

    @data = Reports::RegionService.new(region: @region,
                                       period: @period).call
    @controlled_patients = @data[:controlled_patients]
    @last_registration_value = @data[:cumulative_registrations].values&.last || 0
    @new_registrations = @last_registration_value - @data[:cumulative_registrations].values[-2]
    @adjusted_registration_date = @data[:adjusted_registrations].keys[-4]

    if @region.is_a?(FacilityGroup)
      @data_for_facility = @region.facilities.each_with_object({}) { |facility, hsh|
        hsh[facility.name] = Reports::RegionService.new(region: facility,
                                                        period: @period).call
      }
    else
      @show_current_period = true
      @dashboard_analytics = @region.dashboard_analytics(period: :month,
                                                         prev_periods: 6,
                                                         include_current_period: true)
    end
  end

  def details
    if current_admin.permissions_v2_enabled?
      authorize_v2 { current_admin.accessible_facilities(:view_reports).any? }
    else
      authorize(:dashboard, :show?)
    end

    @data = Reports::RegionService.new(region: @region,
                                       period: @period).call
    @controlled_patients = @data[:controlled_patients]
    @registrations = @data[:cumulative_registrations]
    @last_registration_value = @data[:cumulative_registrations].values&.last || 0
    @adjusted_registration_date = @data[:adjusted_registrations].keys[-4]

    @dashboard_analytics = @region.dashboard_analytics(period: @period.type, prev_periods: 6)

    if @region.is_a?(Facility)
      @recent_blood_pressures = paginate(@region.recent_blood_pressures)
    end
  end

  def cohort
    if current_admin.permissions_v2_enabled?
      authorize_v2 { current_admin.accessible_facilities(:view_reports).any? }
    else
      authorize(:dashboard, :show?)
    end
    periods = @period.downto(5)

    @cohort_data = CohortService.new(region: @region, periods: periods).call
  end

  def download
    if current_admin.permissions_v2_enabled?
      authorize_v2 { current_admin.accessible_facilities(:view_reports).any? }
    else
      authorize(:dashboard, :show?)
    end
    @period = Period.new(type: params[:period], value: Date.current)
    unless @period.valid?
      raise ArgumentError, "invalid Period #{@period} #{@period.inspect}"
    end

    @cohort_analytics = @region.cohort_analytics(period: @period.type, prev_periods: 6)
    @dashboard_analytics = @region.dashboard_analytics(period: @period.type, prev_periods: 6)

    respond_to do |format|
      format.csv do
        if @region.is_a?(FacilityGroup)
          set_facility_keys
          send_data render_to_string("facility_group_cohort.csv.erb")
        else
          send_data render_to_string("cohort.csv.erb")
        end
      end
    end
  end

  private

  def set_facility_keys
    district = {
      id: :total,
      name: "Total"
    }.with_indifferent_access

    facilities = @region.facilities.order(:name).map { |facility|
      {
        id: facility.id,
        name: facility.name,
        type: facility.facility_type
      }.with_indifferent_access
    }

    @facility_keys = [district, *facilities]
  end

  def set_period
    period_params = report_params[:period].presence || Reports::RegionService.default_period.attributes
    @period = Period.new(period_params)
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
