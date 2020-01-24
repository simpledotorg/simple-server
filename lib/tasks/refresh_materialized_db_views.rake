# frozen_string_literal: true

desc 'Refresh materialized views for dashboards'
task refresh_materialized_db_views: :environment do
  # LatestBloodPressuresPerPatientPerMonth should be refreshed before
  # LatestBloodPressuresPerPatientPerQuarter and LatestBloodPressuresPerPatient

  Rails.logger.info 'Refreshing LatestBloodPressuresPerPatientPerMonth'
  LatestBloodPressuresPerPatientPerMonth.refresh

  Rails.logger.info 'Refreshing LatestBloodPressuresPerPatient'
  LatestBloodPressuresPerPatient.refresh

  Rails.logger.info 'Refreshing LatestBloodPressuresPerPatientPerQuarter'
  LatestBloodPressuresPerPatientPerQuarter.refresh
end
