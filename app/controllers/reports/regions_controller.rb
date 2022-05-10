class Reports::RegionsController < AdminController
  include Pagination
  include GraphicsDownload
  include RegionSearch

  before_action :set_period, only: [:show, :cohort, :diabetes]
  before_action :set_page, only: [:details]
  before_action :set_per_page, only: [:details]
  before_action :find_region, except: [:index, :fastindex, :monthly_district_data_report]
  before_action :show_region_search
  around_action :set_reporting_time_zone
  after_action :log_cache_metrics
  delegate :cache, to: Rails

  INDEX_CACHE_KEY = "v3"

  def index
    if current_admin.feature_enabled?(:regions_fast_index)
      fastindex
      render action: :fastindex
    else
      logger.info("regions#index: action called")
      accessible_facility_regions = authorize { current_admin.accessible_facility_regions(:view_reports) }

      cache_key = current_admin.regions_access_cache_key
      cache_version = "#{accessible_facility_regions.cache_key}/#{INDEX_CACHE_KEY}"

      @accessible_regions = cache.fetch(cache_key, force: bust_cache?, version: cache_version, expires_in: 7.days) {
        accessible_facility_regions.each_with_object({}) { |facility, result|
          ancestors = facility.cached_ancestors.map { |facility| [facility.region_type, facility] }.to_h
          org, state, district, block = ancestors.values_at("organization", "state", "district", "block")
          result[org] ||= {}
          result[org][state] ||= {}
          result[org][state][district] ||= {}
          result[org][state][district][block] ||= []
          result[org][state][district][block] << facility
        }
      }
      logger.info { "regions#index: Current admin has #{accessible_facility_regions.size} facility regions" }
    end
  end

  def fastindex
    logger.info("regions#fastindex: action called")
    accessible_facility_regions = authorize { current_admin.accessible_facility_regions(:view_reports) }

    @org = Region.organization_regions.first
    @region_tree = RegionTreeService.new(@org).with_facilities!(accessible_facility_regions)
    logger.info { "regions#fastindex: Current admin has #{accessible_facility_regions.size} facility regions" }
  end

  def show
    start_period = @period.advance(months: -(Reports::MAX_MONTHS_OF_DATA - 1))
    range = Range.new(start_period, @period)
    @repository = Reports::Repository.new(@region, periods: range)
    @presenter = Reports::RepositoryPresenter.new(@repository)
    @data = @presenter.call(@region)
    @with_ltfu = with_ltfu?

    @child_regions = @region.reportable_children
    repo = Reports::Repository.new(@child_regions, periods: @period)

    @children_data = @child_regions.map { |region|
      slug = region.slug
      {
        region: region,
        adjusted_patient_counts: repo.adjusted_patients[slug],
        controlled_patients: repo.controlled[slug],
        controlled_patients_rate: repo.controlled_rates[slug],
        uncontrolled_patients: repo.uncontrolled[slug],
        uncontrolled_patients_rate: repo.uncontrolled_rates[slug],
        missed_visits: repo.missed_visits[slug],
        missed_visits_rate: repo.missed_visits_rate[slug],
        registrations: repo.monthly_registrations[slug],
        cumulative_patients: repo.cumulative_assigned_patients[slug],
        cumulative_registrations: repo.cumulative_registrations[slug]
      }
    }
    respond_to do |format|
      format.html
      format.js
      format.json { render json: @data }
    end
  end

  # We display two ranges of data on this page - the chart range is for the LTFU chart,
  # and the period_range is the data we display in the detail tables.
  def details
    @period = Period.month(Time.current)
    months = -(Reports::MAX_MONTHS_OF_DATA - 1)
    chart_range = (@period.advance(months: months)..@period)
    @period_range = Range.new(@period.advance(months: -5), @period)

    regions = if @region.facility_region?
      [@region]
    else
      [@region, @region.reportable_children].flatten
    end

    if current_admin.feature_enabled?(:show_call_results) && @region.state_region?
      regions.concat(@region.district_regions)
    end

    @repository = Reports::Repository.new(regions, periods: @period_range)
    chart_repo = Reports::Repository.new(@region, periods: chart_range)

    @chart_data = {
      patient_breakdown: PatientBreakdownService.call(region: @region, period: @period),
      ltfu_trend: ltfu_chart_data(chart_repo, chart_range),
      **medications_dispensation_data
    }

    if @region.facility_region?
      @recent_blood_pressures = paginate(
        @region.source.blood_pressures.for_recent_bp_log.includes(:patient, :facility)
      )
    end
  end

  def cohort
    authorize { current_admin.accessible_facilities(:view_reports).any? }
    periods = @period.downto(5)

    @cohort_data = CohortService.new(region: @region, periods: periods).call
  end

  def diabetes
    unless current_admin.feature_enabled?(:diabetes_management_reports) && @region.diabetes_management_enabled?
      raise ActionController::RoutingError.new("Not Found")
    end

    start_period = @period.advance(months: -(Reports::MAX_MONTHS_OF_DATA - 1))
    range = Range.new(start_period, @period)
    @repository = Reports::Repository.new(@region, periods: range)
    @presenter = Reports::RepositoryPresenter.new(@repository)
    @data = @presenter.call(@region)
    @with_ltfu = with_ltfu?

    authorize { current_admin.accessible_facilities(:view_reports).any? }
  end

  def download
    authorize { current_admin.accessible_facilities(:view_reports).any? }
    @period = Period.new(type: params[:period], value: Date.current)
    unless @period.valid?
      raise ArgumentError, "Invalid Period #{@period} #{@period.inspect}"
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

  def monthly_district_data_report
    @region ||= authorize { current_admin.accessible_district_regions(:view_reports).find_by!(slug: report_params[:id]) }
    @period = Period.month(params[:period] || Date.current)
    @medications_dispensation_enabled = current_admin.feature_enabled?(:medications_dispensation)
    csv = MonthlyDistrictDataService.new(@region, @period, medications_dispensation_enabled: @medications_dispensation_enabled).report
    report_date = @period.to_s.downcase
    filename = "monthly-facility-data-#{@region.slug}-#{report_date}.csv"

    respond_to do |format|
      format.csv do
        send_data csv, filename: filename
      end
    end
  end

  def monthly_state_data_report
    @region ||= authorize { current_admin.accessible_state_regions(:view_reports).find_by!(slug: report_params[:id]) }
    @period = Period.month(params[:period] || Date.current)
    @medications_dispensation_enabled = current_admin.feature_enabled?(:medications_dispensation)
    csv = MonthlyStateDataService.new(@region, @period, medications_dispensation_enabled: @medications_dispensation_enabled).report
    report_date = @period.to_s.downcase
    filename = "monthly-district-data-#{@region.slug}-#{report_date}.csv"

    respond_to do |format|
      format.csv do
        send_data csv, filename: filename
      end
    end
  end

  def monthly_district_report
    return unless current_admin.feature_enabled?(:monthly_district_report)

    @region ||= authorize { current_admin.accessible_district_regions(:view_reports).find_by!(slug: report_params[:id]) }
    @period = Period.month(params[:period] || Date.current)
    zip = MonthlyDistrictReport::Exporter.new(@region, @period).export
    report_date = @period.to_s.downcase
    filename = "monthly-district-report-#{@region.slug}-#{report_date}.zip"

    respond_to do |format|
      format.zip do
        send_data zip, filename: filename
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
    @dashboard_analytics = @region.dashboard_analytics(period: :quarter, prev_periods: 4, include_current_period: false)

    whatsapp_graphics_handler(
      @region.organization.name,
      @region.name
    )
  end

  private

  def ltfu_chart_data(repo, range)
    {
      cumulative_assigned_patients: repo.cumulative_assigned_patients[@region.slug],
      ltfu_patients: repo.ltfu[@region.slug],
      ltfu_patients_rate: repo.ltfu_rates[@region.slug],
      period_info: range.each_with_object({}) { |period, hsh| hsh[period] = period.to_hash }
    }
  end

  def medications_dispensation_data
    if current_admin.feature_enabled?(:medications_dispensation)
      {medications_dispensation: MedicationDispensationService.call(region: @region, period: @period)}
    else
      {}
    end
  end

  def accessible_region?(region, action)
    return false unless region.reportable_region?
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
    period_params = report_params[:period].presence || Reports.default_period.attributes
    @period = Period.new(period_params)
  end

  def find_region
    report_scope = report_params[:report_scope]
    @region ||= authorize {
      case report_scope
      when "organization"
        organization = current_admin.user_access.accessible_organizations(:view_reports).find_by!(slug: report_params[:id])
        organization.region
      when "state"
        current_admin.user_access.accessible_state_regions(:view_reports).find_by!(slug: report_params[:id])
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
    params.permit(:id, :bust_cache, :v2, :report_scope, {period: [:type, :value]})
  end

  def with_ltfu?
    params[:with_ltfu].present?
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
