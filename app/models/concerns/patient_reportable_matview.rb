module PatientReportableMatview
  extend ActiveSupport::Concern
  include PatientReportable
  LTFU_TIME = PatientReportable::LTFU_TIME

  included do
    def self.refresh
      ActiveRecord::Base.transaction do
        ActiveRecord::Base.connection.execute("SET LOCAL TIME ZONE '#{CountryConfig.current[:time_zone]}'")

        Scenic.database.refresh_materialized_view(table_name, concurrently: true, cascade: false)
      end
    end

    scope :with_hypertension, -> { where("medical_history_hypertension = ?", "yes") }
    scope :excluding_dead, -> { where.not(patient_status: :dead) }

    scope :ltfu_as_of, ->(date) do
      where.not("bp_recorded_at > ? AND bp_recorded_at < ?", ltfu_time_ago(date), date.to_date)
        .where("patient_recorded_at < ?", ltfu_time_ago(date))
    end

    scope :not_ltfu_as_of, ->(date) do
      where("bp_recorded_at > ? AND bp_recorded_at < ?", ltfu_time_ago(date), date.to_date)
        .or(where("patient_recorded_at >= ?", ltfu_time_ago(date)))
    end
  end
end
