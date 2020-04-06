# frozen_string_literal: true

desc 'Refresh materialized views for dashboards'
task refresh_materialized_db_views: :environment do
  # LatestBloodPressuresPerPatientPerMonth should be refreshed before
  # LatestBloodPressuresPerPatientPerQuarter and LatestBloodPressuresPerPatient
  ActiveRecord::Base.transaction do
    ActiveRecord::Base.connection.execute("SET LOCAL TIME ZONE '#{Rails.application.config.country[:time_zone]}'")

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

    Rails.logger.info 'Refresh complete'
  end
end
