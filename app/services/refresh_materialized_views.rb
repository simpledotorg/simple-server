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
    benchmark("refresh_materialized_views_v2") do
      refresh_v2_views
    end
  end

  def self.tz
    Rails.application.config.country[:time_zone]
  end

  delegate :tz, :set_last_updated_at, to: self

  # LatestBloodPressuresPerPatientPerMonth should be refreshed before
  # LatestBloodPressuresPerPatientPerQuarter and LatestBloodPressuresPerPatient
  def refresh
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

  V2_MAT_VIEWS = %i[
    reporting_patient_blood_pressures_per_month
    reporting_patient_visits_per_month
    reporting_patient_states_per_month
  ].freeze

  def refresh_v2_views
    ActiveRecord::Base.transaction do
      V2_MAT_VIEWS.each do |name|
        benchmark("refresh_materialized_views #{name}") do
          ActiveRecord::Base.connection.execute("REFRESH MATERIALIZED VIEW #{name} WITH DATA")
        end
      end
    end
  end
end
