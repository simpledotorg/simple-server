class Reports::RegionsController < AdminController
  include Pagination
  include GraphicsDownload
  include RegionSearch

  before_action :set_period, except: [:index, :fastindex]
  before_action :set_page, only: [:show, :details, :diabetes]
  before_action :set_per_page, only: [:show, :details, :diabetes]
  before_action :find_region, except: [:index, :fastindex]
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
    @overview_data = @presenter.call(@region)
    @latest_period = Period.current
    @with_ltfu = with_ltfu?
    @with_non_contactable = with_non_contactable?

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

    # ======================
    # DETAILS
    # ======================
    @details_period_range = Range.new(@period.advance(months: -5), @period)
    months = -(Reports::MAX_MONTHS_OF_DATA - 1)

    regions = if @region.facility_region?
      [@region]
    else
      [@region, @region.reportable_children].flatten
    end

    @details_repository = Reports::Repository.new(regions, periods: @details_period_range)

    chart_range = (@period.advance(months: months)..@period)
    chart_repo = Reports::Repository.new(@region, periods: chart_range)
    @details_chart_data = {
      ltfu_trend: ltfu_chart_data(chart_repo, chart_range),
      **medications_dispensation_data(region: @region, period: @period, diagnosis: :hypertension)
    }

    if @region.facility_region?
      @recent_blood_pressures = if Flipper.enabled?(:fast_bp_log)
        paginate(
          BloodPressure.where(facility_id: @region.source_id).for_recent_bp_log.includes(:patient, :facility)
        )
      else
        paginate(
          @region.source.blood_pressures.for_recent_bp_log.includes(:patient, :facility)
        )
      end
    end

    # ======================
    # COHORT REPORTS
    # ======================
    @cohort_period = Period.quarter(Time.current)
    @cohort_data = CohortService.new(region: @region, periods: @cohort_period.downto(5)).call

    @data = @overview_data.merge(@details_chart_data)

    respond_to do |format|
      format.html
      format.js
      format.json { render json: @data }
    end
  end

  # We display two ranges of data on this page - the chart range is for the LTFU chart,
  # and the period_range is the data we display in the detail tables.
  def details
    months = -(Reports::MAX_MONTHS_OF_DATA - 1)
    @details_period_range = Range.new(@period.advance(months: -5), @period)

    regions = if @region.facility_region?
      [@region]
    else
      [@region, @region.reportable_children].flatten
    end

    @repository = Reports::Repository.new(regions, periods: @details_period_range)
    @presenter = Reports::RepositoryPresenter.new(@repository)

    chart_range = (@period.advance(months: months)..@period)
    chart_repo = Reports::Repository.new(@region, periods: chart_range)
    @details_chart_data = {
      ltfu_trend: ltfu_chart_data(chart_repo, chart_range),
      **medications_dispensation_data(region: @region, period: @period, diagnosis: :hypertension)
    }
    @data = @presenter.call(@region)
    @data = @data.merge(@details_chart_data)

    if @region.facility_region?
      @recent_blood_pressures = paginate(
        @region.source.blood_pressures.for_recent_bp_log.includes(:patient, :facility)
      )
    end
  end

  def cohort
    authorize { current_admin.accessible_facilities(:view_reports).any? }

    @cohort_data = CohortService.new(region: @region, periods: @period.downto(5)).call
  end

  def diabetes
    @use_who_standard = Flipper.enabled?(:diabetes_who_standard_indicator, current_admin)
    start_period = @period.advance(months: -(Reports::MAX_MONTHS_OF_DATA - 1))
    range = Range.new(start_period, @period)
    @repository = Reports::Repository.new(@region, periods: range, use_who_standard: @use_who_standard)
    @presenter = Reports::RepositoryPresenter.new(@repository)
    @data = @presenter.call(@region)
    @with_ltfu = with_ltfu?
    @latest_period = Period.current

    authorize { current_admin.accessible_facilities(:view_reports).any? }

    @child_regions = @region.reportable_children.filter { |region| region.diabetes_management_enabled? }
    repo = Reports::Repository.new(@child_regions, periods: @period, use_who_standard: @use_who_standard)

    @children_data = @child_regions.map { |region|
      slug = region.slug
      {
        region: region,
        diabetes_patients_with_bs_taken: repo.diabetes_patients_with_bs_taken[slug],
        diabetes_patients_with_bs_taken_breakdown_rates: repo.diabetes_patients_with_bs_taken_breakdown_rates[slug],
        diabetes_patients_with_bs_taken_breakdown_counts: repo.diabetes_patients_with_bs_taken_breakdown_counts[slug]
      }
    }

    regions = if @region.facility_region?
      [@region]
    else
      [@region, @region.reportable_children].flatten
    end

    months = -(Reports::MAX_MONTHS_OF_DATA - 1)
    @details_period_range = Range.new(@period.advance(months: -5), @period)
    @details_repository = Reports::Repository.new(regions, periods: @details_period_range, use_who_standard: @use_who_standard)
    chart_range = (@period.advance(months: months)..@period)
    chart_repo = Reports::Repository.new(@region, periods: chart_range, use_who_standard: @use_who_standard)
    @details_chart_data = {
      ltfu_trend: diabetes_ltfu_chart_data(chart_repo, chart_range),
      **medications_dispensation_data(region: @region, period: @period, diagnosis: :diabetes)
    }

    @data.merge!(@details_chart_data)

    if @region.facility_region?
      @recent_blood_sugars = paginate(
        @region.source.blood_sugars.for_recent_measures_log.includes(:patient, :facility)
      )
    end
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
          send_data render_to_string("facility_group_cohort"), filename: download_filename
        else
          send_data render_to_string("cohort"), filename: download_filename
        end
      end
    end
  end

  def hypertension_monthly_district_data
    @medications_dispensation_enabled = current_admin.feature_enabled?(:medications_dispensation)
    csv = MonthlyDistrictData::HypertensionDataExporter.new(
      region: @region,
      period: @period,
      medications_dispensation_enabled: @medications_dispensation_enabled
    ).report
    report_date = @period.to_s.downcase
    filename = "monthly-facility-hypertension-data-#{@region.slug}-#{report_date}.csv"

    respond_to do |format|
      format.csv do
        send_data csv, filename: filename
      end
    end
  end

  def diabetes_monthly_district_data
    @medications_dispensation_enabled = current_admin.feature_enabled?(:medications_dispensation)
    csv = MonthlyDistrictData::DiabetesDataExporter.new(
      region: @region,
      period: @period,
      medications_dispensation_enabled: @medications_dispensation_enabled
    ).report
    report_date = @period.to_s.downcase
    filename = "monthly-facility-diabetes-data-#{@region.slug}-#{report_date}.csv"

    respond_to do |format|
      format.csv do
        send_data csv, filename: filename
      end
    end
  end

  def hypertension_monthly_state_data
    @medications_dispensation_enabled = current_admin.feature_enabled?(:medications_dispensation)
    csv = MonthlyStateData::HypertensionDataExporter.new(
      region: @region,
      period: @period,
      medications_dispensation_enabled: @medications_dispensation_enabled
    ).report
    report_date = @period.to_s.downcase
    filename = "monthly-district-hypertension-data-#{@region.slug}-#{report_date}.csv"

    respond_to do |format|
      format.csv do
        send_data csv, filename: filename
      end
    end
  end

  def diabetes_monthly_state_data
    @medications_dispensation_enabled = current_admin.feature_enabled?(:medications_dispensation)
    csv = MonthlyStateData::DiabetesDataExporter.new(
      region: @region,
      period: @period,
      medications_dispensation_enabled: @medications_dispensation_enabled
    ).report
    report_date = @period.to_s.downcase
    filename = "monthly-district-diabetes-data-#{@region.slug}-#{report_date}.csv"

    respond_to do |format|
      format.csv do
        send_data csv, filename: filename
      end
    end
  end

  def hypertension_monthly_district_report
    return unless current_admin.feature_enabled?(:monthly_district_report)

    monthly_district_report(MonthlyDistrictReport::Exporter.new(
      facility_data: MonthlyDistrictReport::Hypertension::FacilityData.new(@region, @period),
      block_data: MonthlyDistrictReport::Hypertension::BlockData.new(@region, @period),
      district_data: MonthlyDistrictReport::Hypertension::DistrictData.new(@region, @period)
    ),
      @region,
      @period,
      diagnosis: :hypertension)
  end

  def diabetes_monthly_district_report
    return unless current_admin.feature_enabled?(:monthly_district_report)

    monthly_district_report(
      MonthlyDistrictReport::Exporter.new(
        facility_data: MonthlyDistrictReport::Diabetes::FacilityData.new(@region, @period),
        block_data: MonthlyDistrictReport::Diabetes::BlockData.new(@region, @period),
        district_data: MonthlyDistrictReport::Diabetes::DistrictData.new(@region, @period)
      ),
      @region,
      @period,
      diagnosis: :diabetes
    )
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

  def monthly_district_report(exporter, region, period, diagnosis:)
    zip = exporter.export

    report_date = period.to_s.downcase
    filename = "monthly-district-#{diagnosis}-report-#{region.slug}-#{report_date}.zip"

    respond_to do |format|
      format.zip do
        send_data zip, filename: filename
      end
    end
  end

  def ltfu_chart_data(repo, range)
    {
      cumulative_assigned_patients: repo.cumulative_assigned_patients[@region.slug],
      ltfu_patients: repo.ltfu[@region.slug],
      ltfu_patients_rate: repo.ltfu_rates[@region.slug],
      period_info: range.each_with_object({}) { |period, hsh| hsh[period] = period.to_hash }
    }
  end

  def diabetes_ltfu_chart_data(repo, range)
    {
      cumulative_assigned_patients: repo.cumulative_assigned_diabetic_patients[@region.slug],
      ltfu_patients: repo.diabetes_ltfu[@region.slug],
      ltfu_patients_rate: repo.diabetes_ltfu_rates[@region.slug],
      period_info: range.each_with_object({}) { |period, hsh| hsh[period] = period.to_hash }
    }
  end

  def medications_dispensation_data(region:, period:, diagnosis:)
    if current_admin.feature_enabled?(:medications_dispensation)
      {medications_dispensation: MedicationDispensationService.call(region: region, period: period, diagnosis: diagnosis)}
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

  def with_non_contactable?
    params[:with_non_contactable].present?
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
