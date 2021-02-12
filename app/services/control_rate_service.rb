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
    @quarterly_report = @report_range.begin.quarter?
    @results = Reports::Result.new(region: @region, period_type: @report_range.begin.type)
    @with_exclusions = with_exclusions
    logger.info class: self.class.name, msg: "created", region: region.id, region_name: region.name,
                report_range: report_range.inspect, facilities: facilities.map(&:id), cache_key: cache_key
  end

  delegate :logger, to: Rails
  attr_reader :facilities
  attr_reader :region
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
    results.registrations_with_exclusions = registration_counts_with_exclusions
    results.earliest_registration_period = registration_counts.keys.first
    results.fill_in_nil_registrations
    results.count_cumulative_registrations
    results.count_adjusted_registrations

    results.controlled_patients = repository.controlled_patients_count[region.slug]
    results.uncontrolled_patients = repository.uncontrolled_patients_count[region.slug]

    results.calculate_percentages(:controlled_patients)
    results.calculate_percentages(:uncontrolled_patients)
    results
  end

  def registration_counts_with_exclusions
    return @registration_counts_with_exclusions if defined? @registration_counts_with_exclusions
    formatter = lambda { |v| quarterly_report? ? Period.quarter(v) : Period.month(v) }

    @registration_counts_with_exclusions =
      region.assigned_patients
        .for_reports(with_exclusions: with_exclusions)
        .group_by_period(report_range.begin.type, :recorded_at, {format: formatter})
        .count
  end

  def registration_counts
    return @registration_counts if defined? @registration_counts
    formatter = lambda { |v| quarterly_report? ? Period.quarter(v) : Period.month(v) }

    @registration_counts =
      region.assigned_patients
        .group_by_period(report_range.begin.type, :recorded_at, {format: formatter})
        .count
  end

  def quarterly_report?
    @quarterly_report
  end

  def cache_key
    if with_exclusions
      "#{self.class}/#{region.cache_key}/#{@periods.end.type}/with_exclusions"
    else
      "#{self.class}/#{region.cache_key}/#{@periods.end.type}"
    end
  end

  def cache_version
    "#{region.cache_version}/#{CACHE_VERSION}"
  end

  def force_cache?
    RequestStore.store[:force_cache]
  end
end
