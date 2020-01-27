# frozen_string_literal: true

desc 'Refresh materialized views for dashboards'
task refresh_materialized_db_views: :environment do
  # LatestBloodPressuresPerPatientPerMonth should be refreshed before
  # LatestBloodPressuresPerPatientPerQuarter and LatestBloodPressuresPerPatient
  ActiveRecord::Base.transaction do
    ActiveRecord::Base.connection.execute("SET LOCAL TIME ZONE '#{ENV['ANALYTICS_TIME_ZONE']}'")

    Rails.logger.info 'Refreshing LatestBloodPressuresPerPatientPerMonth'
    LatestBloodPressuresPerPatientPerMonth.refresh

    Rails.logger.info 'Refreshing LatestBloodPressuresPerPatient'
    LatestBloodPressuresPerPatient.refresh

    Rails.logger.info 'Refreshing LatestBloodPressuresPerPatientPerQuarter'
    LatestBloodPressuresPerPatientPerQuarter.refresh
  end
end
