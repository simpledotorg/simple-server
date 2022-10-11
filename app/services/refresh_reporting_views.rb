class RefreshReportingViews
  prepend SentryHandler
  include ActiveSupport::Benchmarkable
  REPORTING_VIEW_REFRESH_TIME_KEY = "last_reporting_view_refresh_time".freeze
  REPORTING_VIEW_DAILY_REFRESH_KEY = "last_reporting_view_daily_refresh_time".freeze

  # Keep the views below in the order as defined, as they have dependencies on earlier matviews in the lists
  V1_REPORTING_VIEWS = %w[
    LatestBloodPressuresPerPatientPerMonth
    LatestBloodPressuresPerPatient
    BloodPressuresPerFacilityPerDay
    MaterializedPatientSummary
  ].freeze

  # The order for these must remain BPs -> Visits -> States
  V2_REPORTING_VIEWS = %w[
    Reports::Month
    Reports::Facility
    Reports::PatientBloodPressure
    Reports::PatientBloodSugar
    Reports::OverdueCalls
    Reports::PatientVisit
    Reports::Prescriptions
    Reports::PatientFollowUp
    Reports::PatientState
    Reports::FacilityAppointmentScheduledDays
    Reports::FacilityState
    Reports::QuarterlyFacilityState
    Reports::FacilityStateDimension
    Reports::FacilityDailyFollowUpAndRegistration
  ].freeze

  def self.last_updated_at
    Rails.cache.fetch(REPORTING_VIEW_REFRESH_TIME_KEY)
  end

  def self.last_updated_at_facility_daily_follow_ups_and_registrations
    Rails.cache.fetch(REPORTING_VIEW_DAILY_REFRESH_KEY)
  end

  def self.set_last_updated_at
    Rails.cache.write(REPORTING_VIEW_REFRESH_TIME_KEY, Time.current.in_time_zone(tz))
  end

  def self.set_last_updated_at_facility_daily_follow_ups_and_registrations
    Rails.cache.write(REPORTING_VIEW_DAILY_REFRESH_KEY, Time.current.in_time_zone(tz))
  end

  # Refreshes all views by default, or can take an Array of class names if you want to
  # specifically refresh certain matviews.
  def self.call(views: :all)
    new(views: views).call
  end

  def self.refresh_daily_follow_ups_and_registrations
    new(views: ["Reports::FacilityDailyFollowUpAndRegistration"]).call
  end

  def self.refresh_v2
    new(views: V2_REPORTING_VIEWS).call
  end

  attr_reader :logger
  delegate :tz, :set_last_updated_at, to: self

  def initialize(views:)
    @logger = Rails.logger.child(class: self.class.name)
    @all = true if views == :all
    @views = if views == :all
      V1_REPORTING_VIEWS + V2_REPORTING_VIEWS
    else
      views
    end
    if Rails.env.development?
      stdout_logger = Ougai::Logger.new($stdout)
      @logger.extend(Ougai::Logger.broadcast(stdout_logger))
    end
  end

  def call
    logger.info "Beginning full reporting view refresh"
    benchmark_and_statsd("all") do
      refresh
    end
    set_last_updated_at if all_views_refreshed?
    self.class.set_last_updated_at_facility_daily_follow_ups_and_registrations
    if views.any? { |view| view.match?(/Daily/) }
      logger.info "Completed full reporting view refresh"
    end
  end

  def self.tz
    Rails.application.config.country[:time_zone]
  end

  private

  def all_views_refreshed?
    @all == true
  end

  attr_reader :views

  def refresh
    views.each do |name|
      benchmark_and_statsd(name) do
        klass = name.constantize
        klass.refresh
      end
    end
  end

  def benchmark_and_statsd(operation)
    name = "refresh_reporting_views.#{operation}"
    benchmark(name) do
      Datadog::Tracing.trace("refresh_matview", resource: operation) do |span|
        yield
      end
    end
  end
end
