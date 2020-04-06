# frozen_string_literal: true

desc 'Refresh materialized views for dashboards'
task refresh_materialized_db_views: :environment do
  tz = Rails.application.config.country[:time_zone]
  refresh_time_key = Rails.application.config.app_constants[:MATVIEW_REFRESH_TIME_KEY]

  # LatestBloodPressuresPerPatientPerMonth should be refreshed before
  # LatestBloodPressuresPerPatientPerQuarter and LatestBloodPressuresPerPatient
  ActiveRecord::Base.transaction do
    ActiveRecord::Base.connection.execute("SET LOCAL TIME ZONE '#{tz}'")

    Rails.logger.info 'Refreshing LatestBloodPressuresPerPatientPerDay'
    LatestBloodPressuresPerPatientPerDay.refresh

    Rails.logger.info 'Refreshing LatestBloodPressuresPerPatientPerDay'
    LatestBloodPressuresPerPatientPerDay.refresh

    Rails.logger.info 'Refreshing LatestBloodPressuresPerPatientPerMonth'
    LatestBloodPressuresPerPatientPerMonth.refresh

    Rails.logger.info 'Refreshing LatestBloodPressuresPerPatient'
    LatestBloodPressuresPerPatient.refresh

    Rails.logger.info 'Refreshing LatestBloodPressuresPerPatientPerQuarter'
    LatestBloodPressuresPerPatientPerQuarter.refresh

    Rails.logger.info 'Refreshing BloodPressuresPerFacilityPerDay'
    BloodPressuresPerFacilityPerDay.refresh

    Rails.logger.info 'Refreshing PatientRegistrationsPerDayPerFacility'
    PatientRegistrationsPerDayPerFacility.refresh

    Time.use_zone(tz) { Rails.cache.write(refresh_time_key, Time.current) }
    Rails.logger.info "Refresh complete, #{refresh_time_key} written to cache"
  end
end
