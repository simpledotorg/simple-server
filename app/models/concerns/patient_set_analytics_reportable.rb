module PatientSetAnalyticsReportable
  extend ActiveSupport::Concern

  def patient_set_analytics(from_time, to_time)
    Rails.cache.fetch(analytics_cache_key(from_time,to_time)) do
      analytics = Analytics::PatientSetAnalytics.new(report_on_patients, from_time, to_time)

      { newly_enrolled_patients: analytics.newly_enrolled_patients_count,
        returning_patients: analytics.returning_patients_count,
        non_returning_hypertensive_patients: analytics.non_returning_hypertensive_patients_count,
        control_rate: analytics.control_rate,
        unique_patients_enrolled: analytics.unique_patients_count,
        blood_pressures_recorded_per_week: analytics.blood_pressures_recorded_per_week(12),
        newly_enrolled_patients_per_month: analytics.newly_enrolled_patients_count_per_month(@months_previous),
        non_returning_hypertensive_patients_per_month: analytics.non_returning_hypertensive_patients_count_per_month(4),
        control_rate_per_month: analytics.control_rate_per_month(4),
        unique_patients_recorded_per_month: analytics.unique_patients_count_per_month(4) }
    end
  end

  private

  def analytics_cache_key(from_time, to_time)
    "analytics/#{time_cache_key(from_time)}/#{time_cache_key(to_time)}/#{cache_key}"
  end

  def time_cache_key(time)
    time.strftime('%Y-%m-%d')
  end
end
