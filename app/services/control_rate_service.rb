class ControlRateService
  CACHE_VERSION = 9

  # Can be initialized with _either_ a Period range or a single Period to calculate
  # control rates. We need to handle a single period for calculating point in time benchmarks.
  #
  # Note that for the range the returned values will be for each Period going back
  # to the beginning of registrations for the region.
  def initialize(region, periods:, with_exclusions: false)
    @region = region
    @facilities = region.facilities
    @periods = periods
    @report_range = periods
    @period_type = @report_range.begin.type
    @quarterly_report = @report_range.begin.quarter?
    @results = Reports::Result.new(region: @region, period_type: @report_range.begin.type)
    @with_exclusions = with_exclusions
    logger.info class: self.class.name, msg: "created", region: region.id, region_name: region.name,
                report_range: report_range.inspect, facilities: facilities.map(&:id), cache_key: cache_key
  end

  delegate :logger, to: Rails
  attr_reader :facilities
  attr_reader :region
  attr_reader :period_type
  attr_reader :report_range
  attr_reader :results
  attr_reader :with_exclusions

  # We cache all the data for a region to improve performance and cache hits, but then return
  # just the data the client requested
  def call
    all_cached_data.report_data_for(report_range)
  end

  private

  def all_cached_data
    Rails.cache.fetch(cache_key, version: cache_version, expires_in: 7.days, force: force_cache?) {
      fetch_all_data
    }
  end

  def repository
    @repository ||= Reports::Repository.new(region, periods: results.full_data_range, with_exclusions: with_exclusions)
  end

  def fetch_all_data
    results.registrations = registration_counts
    results.assigned_patients = assigned_patients_counts
    results.earliest_registration_period = [registration_counts.keys.first, assigned_patients_counts.keys.first].compact.min
    results.full_data_range.each do |(period, count)|
      results.ltfu_patients[period] = ltfu_patients(period)
    end
    results.fill_in_nil_registrations
    results.count_cumulative_registrations
    results.count_cumulative_assigned_patients
    results.count_adjusted_registrations_with_ltfu

    if with_exclusions
      results.count_adjusted_registrations
    else
      results.adjusted_registrations = results.adjusted_registrations_with_ltfu
    end

    results.controlled_patients = repository.controlled_patients_count[region.slug]
    results.controlled_patients_with_ltfu = repository.controlled_patients_count[region.slug]
    results.uncontrolled_patients = repository.uncontrolled_patients_count[region.slug]

    results.calculate_percentages(:controlled_patients)
    results.calculate_percentages(:controlled_patients_with_ltfu)
    results.calculate_percentages(:uncontrolled_patients)
    results.calculate_percentages(:ltfu_patients)
    results
  end

  def registration_counts
    return @registration_counts if defined? @registration_counts

    @registration_counts = RegisteredPatientsQuery.new.count(region, period_type)
  end

  def assigned_patients_counts
    return @assigned_patients_counts if defined? @assigned_patients_counts

    @assigned_patients_counts = AssignedPatientsQuery.new.count(region, period_type, with_exclusions: with_exclusions)
  end

  def ltfu_patients(period)
    return 0 unless with_exclusions

    Patient
      .for_reports(with_exclusions: with_exclusions)
      .where(assigned_facility: facilities.pluck(:id))
      .ltfu_as_of(period.start_date)
      .count
  end

  def quarterly_report?
    @quarterly_report
  end

  def cache_key
    if with_exclusions
      "#{self.class}/#{region.cache_key}/#{period_type}/with_exclusions"
    else
      "#{self.class}/#{region.cache_key}/#{period_type}"
    end
  end

  def cache_version
    "#{region.cache_version}/#{CACHE_VERSION}"
  end

  def force_cache?
    RequestStore.store[:force_cache]
  end

  def group_date_formatter
    lambda { |v| quarterly_report? ? Period.quarter(v) : Period.month(v) }
  end
end
