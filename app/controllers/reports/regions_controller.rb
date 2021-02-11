class Reports::RegionsController < AdminController
  include Pagination
  include GraphicsDownload

  before_action :set_period, only: [:show, :details, :cohort]
  before_action :set_page, only: [:details]
  before_action :set_per_page, only: [:details]
  before_action :set_force_cache
  before_action :find_region, except: [:index]
  around_action :set_time_zone
  after_action :log_cache_metrics
  delegate :cache, to: Rails

  def index
    accessible_facility_regions = authorize { current_admin.accessible_facility_regions(:view_reports) }

    cache_key = "#{current_admin.cache_key}/regions/index"
    cache_version = "#{accessible_facility_regions.cache_key} / v2"
    @accessible_regions = cache.fetch(cache_key, version: cache_version, expires_in: 7.days) {
      accessible_facility_regions.each_with_object({}) { |facility, result|
        ancestors = Hash[facility.cached_ancestors.map { |facility| [facility.region_type, facility] }]
        org, state, district, block = ancestors.values_at("organization", "state", "district", "block")
        result[org] ||= {}
        result[org][state] ||= {}
        result[org][state][district] ||= {}
        result[org][state][district][block] ||= []
        result[org][state][district][block] << facility
      }
    }
  end

  def show
    @data = Reports::RegionService.new(region: @region, period: @period).call
    @last_registration_value = @data[:cumulative_registrations].values&.last || 0
    @new_registrations = @last_registration_value - (@data[:cumulative_registrations].values[-2] || 0)
    @adjusted_registration_date = @data[:adjusted_registrations].keys[-4]

    @children = @region.reportable_children

    repository = Reports::Repository.new(@children, periods: @period, with_exclusions: report_with_exclusions?)
    @children_data_derp = @children.map { |child|
      fetcher = repository.for_region_and_period(child, @period)
      {
        region: child,
        controlled_patients: fetch.controlled_patients_count,
        controlled_patients_rate: fetch.controlled_patients_rate,
        uncontrolled_patients: fetch.uncontrolled_patients,
        uncontrolled_patients_rate: fetch.uncontrolled_patients_rate,
        missed_visits: fetch.missed_visits,
        missed_visits_percentage: fetch.fetch.missed_visits_rate,
        registrations: fetch.assigned_patients_count,
        cumulative_patients: fetch.cumulative_registrations
      }
    }

    @children_data = @children.map { |child|
      result = Reports::Result.new(region: child, period_type: @period.type)
      result.registrations = repository.assigned_patients_count[child.slug]
      result.registrations_with_exclusions = repository.assigned_patients_count[child.slug]
      result.earliest_registration_period = result.registrations.keys.first
      result.fill_in_nil_registrations
      result.count_cumulative_registrations
      result.count_adjusted_registrations
      result.controlled_patients = repository.controlled_patients_count[child.slug]
      result.uncontrolled_patients = repository.uncontrolled_patients_count[child.slug]
      result.calculate_percentages(:controlled_patients)
      result.calculate_percentages(:uncontrolled_patients)
      result
    }
  end

  def details
    authorize { current_admin.accessible_facilities(:view_reports).any? }

    @show_current_period = true
    @dashboard_analytics = @region.dashboard_analytics(period: @period.type,
                                                       prev_periods: 6,
                                                       include_current_period: true)

    region_source = @region.source
    if region_source.respond_to?(:recent_blood_pressures)
      @recent_blood_pressures = paginate(region_source.recent_blood_pressures)
    end
  end

  def cohort
    authorize { current_admin.accessible_facilities(:view_reports).any? }
    periods = @period.downto(5)

    @cohort_data = CohortService.new(region: @region, periods: periods, with_exclusions: report_with_exclusions?).call
  end

  def download
    authorize { current_admin.accessible_facilities(:view_reports).any? }
    @period = Period.new(type: params[:period], value: Date.current)
    unless @period.valid?
      raise ArgumentError, "invalid Period #{@period} #{@period.inspect}"
    end

    @cohort_analytics = @region.cohort_analytics(period: @period.type, prev_periods: 6)
    @dashboard_analytics = @region.dashboard_analytics(period: @period.type, prev_periods: 6)

    respond_to do |format|
      format.csv do
        if @region.district_region?
          set_facility_keys
          send_data render_to_string("facility_group_cohort.csv.erb"), filename: download_filename
        else
          send_data render_to_string("cohort.csv.erb"), filename: download_filename
        end
      end
    end
  end

  def whatsapp_graphics
    authorize { current_admin.accessible_facilities(:view_reports).any? }

    previous_quarter = Quarter.current.previous_quarter
    @year, @quarter = previous_quarter.year, previous_quarter.number
    @quarter = params[:quarter].to_i if params[:quarter].present?
    @year = params[:year].to_i if params[:year].present?

    @cohort_analytics = @region.cohort_analytics(period: :quarter, prev_periods: 3)
    @dashboard_analytics = @region.dashboard_analytics(period: :quarter, prev_periods: 4)

    whatsapp_graphics_handler(
      @region.organization.name,
      @region.name
    )
  end

  private

  def accessible_region?(region, action)
    current_admin.region_access(memoized: true).accessible_region?(region, action)
  end

  helper_method :accessible_region?

  def download_filename
    time = Time.current.to_s(:number)
    region_name = @region.name.tr(" ", "-")
    "#{@region.region_type.to_s.underscore}-#{@period.adjective.downcase}-cohort-report_#{region_name}_#{time}.csv"
  end

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
    report_scope = report_params[:report_scope]
    @region ||= authorize {
      case report_scope
      when "state"
        current_admin.user_access.accessible_state_regions(:view_reports).find_by!(slug: report_params[:id])
      when "facility_district"
        scope = current_admin.accessible_facilities(:view_reports)
        FacilityDistrict.new(name: report_params[:id], scope: scope)
      when "district"
        current_admin.accessible_district_regions(:view_reports).find_by!(slug: report_params[:id])
      when "block"
        current_admin.accessible_block_regions(:view_reports).find_by!(slug: report_params[:id])
      when "facility"
        current_admin.accessible_facility_regions(:view_reports).find_by!(slug: report_params[:id])
      else
        raise ActiveRecord::RecordNotFound, "unknown report_scope #{report_scope}"
      end
    }
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

  def report_with_exclusions?
    current_admin.feature_enabled?(:report_with_exclusions)
  end

  def log_cache_metrics
    stats = RequestStore[:cache_stats] || {}
    hit_rate = percentage(stats.fetch(:hits, 0), stats.fetch(:reads, 0))
    logger.info class: self.class.name, msg: "cache hit rate: #{hit_rate}% stats: #{stats.inspect}"
  end

  def percentage(numerator, denominator)
    return 0 if denominator == 0 || numerator == 0
    ((numerator.to_f / denominator) * 100).round(2)
  end
end
