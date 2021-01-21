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

  def call
    benchmark("refresh_materialized_views") do
      refresh
    end
  end

  def self.tz
    Rails.application.config.country[:time_zone]
  end

  delegate :tz, :set_last_updated_at, to: self

  def refresh
    # LatestBloodPressuresPerPatientPerMonth should be refreshed before
    # LatestBloodPressuresPerPatientPerQuarter and LatestBloodPressuresPerPatient
    ActiveRecord::Base.transaction do
      ActiveRecord::Base.connection.execute("SET LOCAL TIME ZONE '#{tz}'")

      benchmark("refresh_materialized_views LatestBloodPressuresPerPatientPerMonth") do
        LatestBloodPressuresPerPatientPerMonth.refresh
      end

      benchmark("refresh_materialized_views LatestBloodPressuresPerPatient") do
        LatestBloodPressuresPerPatient.refresh
      end

      benchmark("refresh_materialized_views LatestBloodPressuresPerPatientPerQuarter") do
        LatestBloodPressuresPerPatientPerQuarter.refresh
      end

      benchmark("refresh_materialized_views BloodPressuresPerFacilityPerDay") do
        BloodPressuresPerFacilityPerDay.refresh
      end

      benchmark("refresh_materialized_views PatientRegistrationsPerDayPerFacility") do
        PatientRegistrationsPerDayPerFacility.refresh
      end

      benchmark("refresh_materialized_views MaterializedPatientSummary") do
        MaterializedPatientSummary.refresh
      end

      set_last_updated_at
    end
  end
end
