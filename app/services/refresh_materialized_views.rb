class RefreshMaterializedViews
  include ActiveSupport::Benchmarkable

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

  def tz
    Rails.application.config.country[:time_zone]
  end

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

      Rails.cache.write(Constants::MATVIEW_REFRESH_TIME_KEY, Time.current.in_time_zone(tz).iso8601)
    end
  end
end
