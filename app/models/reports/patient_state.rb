module Reports
  class PatientState < Reports::View
    self.table_name = "reporting_patient_states"
    belongs_to :patient

    enum htn_care_state: {
      dead: "dead",
      under_care: "under_care",
      lost_to_follow_up: "lost_to_follow_up"
    }, _prefix: :htn_care_state

    def self.materialized?
      false
    end

    def self.partitioned?
      true
    end

    def self.partitioned_refresh(refresh_month)
      ActiveRecord::Base.connection.exec_query(
        "CALL simple_reporting.add_shard_to_table('#{refresh_month}', 'reporting_patient_states')"
      )
    end

    def self.by_assigned_region(region_or_source)
      region = region_or_source.region
      where("assigned_#{region.region_type}_region_id" => region.id)
    end

    def self.by_month_date(month_date)
      where(month_date: month_date)
    end
  end
end
