class RefreshMaterializedViews
  include ActiveSupport::Benchmarkable
  MATVIEW_REFRESH_TIME_KEY = "last_materialized_view_refresh_time".freeze

  def self.last_updated_at
    Rails.cache.fetch(MATVIEW_REFRESH_TIME_KEY)
  end

  def self.set_last_updated_at
    Rails.cache.write(MATVIEW_REFRESH_TIME_KEY, Time.current.in_time_zone(tz))
  end

  def self.call
    new.call
  end

  def logger
    @logger ||= Rails.logger.child(class: self.class.name)
  end

  def benchmark_and_statsd(operation)
    name = "refresh_matviews.#{operation}"
    benchmark(name) do
      Statsd.instance.time(name) do
        yield
      end
    end
  end

  def call
    benchmark_and_statsd("all_v1") do
      refresh_v1
    end
    benchmark_and_statsd("all_v2") do
      refresh_v2
    end
  end

  def self.tz
    Rails.application.config.country[:time_zone]
  end

  delegate :tz, :set_last_updated_at, to: self

  V1_MATVIEWS = %w[
    LatestBloodPressuresPerPatientPerMonth
    LatestBloodPressuresPerPatient
    LatestBloodPressuresPerPatientPerQuarter
    BloodPressuresPerFacilityPerDay
    PatientRegistrationsPerDayPerFacility
    MaterializedPatientSummary
  ].freeze

  # The order for these must remain BPs -> Visits -> States
  V2_MATVIEWS = %w[
    ReportingPipeline::PatientBloodPressuresPerMonth
    ReportingPipeline::PatientVisitsPerMonth
    ReportingPipeline::PatientStatesPerMonth
  ].freeze

  # LatestBloodPressuresPerPatientPerMonth should be refreshed before
  # LatestBloodPressuresPerPatientPerQuarter and LatestBloodPressuresPerPatient
  def refresh_v1
    ActiveRecord::Base.transaction do
      ActiveRecord::Base.connection.execute("SET LOCAL TIME ZONE '#{tz}'")
      V1_MATVIEWS.each do |name|
        benchmark_and_statsd(name) do
          klass = name.constantize
          klass.refresh
        end
      end
      set_last_updated_at
    end
  end

  def refresh_v2
    # ActiveRecord::Base.transaction do
      ActiveRecord::Base.connection.execute("SET LOCAL TIME ZONE '#{tz}'")
      V2_MATVIEWS.each do |name|
        benchmark_and_statsd(name) do
          klass = name.constantize
          klass.refresh
        end
      end
    # end
  end
end
