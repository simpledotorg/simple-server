class RefreshReportingViews
  include ActiveSupport::Benchmarkable
  REPORTING_VIEW_REFRESH_TIME_KEY = "last_reporting_view_refresh_time".freeze

  def self.last_updated_at
    Rails.cache.fetch(REPORTING_VIEW_REFRESH_TIME_KEY)
  end

  def self.set_last_updated_at
    Rails.cache.write(REPORTING_VIEW_REFRESH_TIME_KEY, Time.current.in_time_zone(tz))
  end

  def self.call
    new.call
  end

  attr_reader :logger

  def initialize
    @logger = Rails.logger.child(class: self.class.name)
    if Rails.env.development?
      stdout_logger = Ougai::Logger.new($stdout)
      @logger.extend(Ougai::Logger.broadcast(stdout_logger))
    end
  end

  def benchmark_and_statsd(operation)
    name = "refresh_reporting_views.#{operation}"
    benchmark(name) do
      Statsd.instance.time(name) do
        yield
      end
    end
  end

  def call
    logger.info "Beginning full reporting view refresh"
    benchmark_and_statsd("all_v1") do
      refresh_v1
    end
    benchmark_and_statsd("all_v2") do
      refresh_v2
    end
    logger.info "Completed full reporting view refresh"
  end

  def self.tz
    Rails.application.config.country[:time_zone]
  end

  delegate :tz, :set_last_updated_at, to: self

  V1_REPORTING_VIEWS = %w[
    LatestBloodPressuresPerPatientPerMonth
    LatestBloodPressuresPerPatient
    LatestBloodPressuresPerPatientPerQuarter
    BloodPressuresPerFacilityPerDay
    PatientRegistrationsPerDayPerFacility
    MaterializedPatientSummary
  ].freeze

  # The order for these must remain BPs -> Visits -> States
  V2_REPORTING_VIEWS = %w[
    Reports::Month
    Reports::Facility
    Reports::PatientBloodPressure
    Reports::PatientVisit
    Reports::PatientState
    Reports::FacilityState
    Reports::QuarterlyFacilityState
    Reports::PatientFollowUp
  ].freeze

  # LatestBloodPressuresPerPatientPerMonth should be refreshed before
  # LatestBloodPressuresPerPatientPerQuarter and LatestBloodPressuresPerPatient
  def refresh_v1
    ActiveRecord::Base.transaction do
      ActiveRecord::Base.connection.execute("SET LOCAL TIME ZONE '#{tz}'")
      V1_REPORTING_VIEWS.each do |name|
        benchmark_and_statsd(name) do
          klass = name.constantize
          klass.refresh
        end
      end
      set_last_updated_at
    end
  end

  def refresh_v2
    V2_REPORTING_VIEWS.each do |name|
      benchmark_and_statsd(name) do
        klass = name.constantize
        klass.refresh
      end
    end
  end
end
