class ControlRateService
  include BustCache
  CACHE_VERSION = 13

  # Can be initialized with _either_ a Period range or a single Period to calculate
  # control rates. We need to handle a single period for calculating point in time benchmarks.
  #
  # Note that for the range the returned values will be for each Period going back
  # to the beginning of registrations for the region.
  def initialize(region, periods:)
    @region = region
    @facilities = region.facilities
    @periods = periods
    @report_range = periods
    @period_type = @report_range.begin.type
    @quarterly_report = @report_range.begin.quarter?
    @results = Reports::Result.new(region: @region, period_type: @report_range.begin.type)
    logger.info class: self.class.name, msg: "created", region: region.id, region_name: region.name,
                report_range: report_range.inspect, facilities: facilities.map(&:id), cache_key: cache_key
  end

  delegate :logger, to: Rails
  delegate :slug, to: :region

  attr_reader :facilities
  attr_reader :region
  attr_reader :period_type
  attr_reader :report_range
  attr_reader :results

  # We cache all the data for a region to improve performance and cache hits, but then return
  # just the data the client requested
  def call
    all_cached_data.report_data_for(report_range)
  end

  private

  def all_cached_data
    Rails.cache.fetch(cache_key, version: cache_version, expires_in: 7.days, force: bust_cache?) {
      fetch_all_data
    }
  end

  def repository
    @repository ||= Reports::Repository.new(region, periods: report_range)
  end

  def fetch_all_data
    results.earliest_registration_period = repository.earliest_patient_recorded_at_period[slug]
    results.registrations = repository.registration_counts[slug]
    results.assigned_patients = repository.assigned_patients_count[slug]
    results.cumulative_registrations = repository.cumulative_registrations[slug]
    results.cumulative_assigned_patients = repository.cumulative_assigned_patients_count[slug]
    results.adjusted_patient_counts_with_ltfu = repository.adjusted_patient_counts_with_ltfu[slug]
    results.adjusted_patient_counts = repository.adjusted_patient_counts_without_ltfu[slug]

    results.full_data_range.each do |(period, count)|
      results.ltfu_patients[period] = ltfu_patients(period)
    end

    results.controlled_patients = repository.controlled_patients_count[region.slug]
    results.uncontrolled_patients = repository.uncontrolled_patients_count[region.slug]

    results.controlled_patients_rate = repository.controlled_patient_rates[slug]
    results.uncontrolled_patients_rate = repository.uncontrolled_patient_rates[slug]

    results.calculate_percentages(:controlled_patients, with_ltfu: true)
    results.calculate_percentages(:uncontrolled_patients, with_ltfu: true)
    results.calculate_percentages(:ltfu_patients)
    results
  end

  def ltfu_patients(period)
    Patient.for_reports.where(assigned_facility: facilities.pluck(:id)).ltfu_as_of(period.end).count
  end

  def quarterly_report?
    @quarterly_report
  end

  def cache_key
    "#{self.class}/#{region.cache_key}/#{period_type}"
  end

  def cache_version
    "#{region.cache_version}/#{CACHE_VERSION}"
  end

  def group_date_formatter
    lambda { |v| quarterly_report? ? Period.quarter(v) : Period.month(v) }
  end
end
