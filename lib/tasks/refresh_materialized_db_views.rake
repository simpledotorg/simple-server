# frozen_string_literal: true

desc "Refresh materialized views for dashboards"
task refresh_materialized_db_views: :environment do
  include ActiveSupport::Benchmarkable

  tz = Rails.application.config.country[:time_zone]

  # We need to have a logger in scope for the benchmark method below to work
  def logger
    Rails.logger
  end

  benchmark("refresh_materialized_views") do
    # LatestBloodPressuresPerPatientPerMonth should be refreshed before
    # LatestBloodPressuresPerPatientPerQuarter and LatestBloodPressuresPerPatient
    ActiveRecord::Base.transaction do
      ActiveRecord::Base.connection.execute("SET LOCAL TIME ZONE '#{tz}'")

      benchmark("refresh_materialized_views LatestBloodPressuresPerPatientPerDay") do
        LatestBloodPressuresPerPatientPerDay.refresh
      end

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
    end
  end
end
