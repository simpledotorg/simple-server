module Reports
  class FacilityStateGroup < Reports::View
    self.table_name = "reporting_facility_state_groups"

    belongs_to :facility

    def self.materialized?
      true
    end

    NON_COUNT_FIELDS = %i[
      block_region_id
      district_region_id
      facility_id
      facility_region_id
      facility_region_slug
      month_date
      state_region_id
    ]

    def self.totals(facility)
      count_columns = column_names - NON_COUNT_FIELDS.map(&:to_s)
      calculations = count_columns.map { |c| "sum(#{c}) as #{c}" }
      where(facility: facility).select(calculations).to_a.first
    end

    # Returns the total counts for a facility of either registrations or follow ups
    #
    # monthly_registrations_all
    # monthly_registrations_dm_all
    # monthly_registrations_htn_all
    # monthly_follow_ups_all
    # monthly_follow_ups_dm_all
    # monthly_follow_ups_htn_all
    def self.total(facility, metric, diagnosis, gender: "all")
      diagnosis_code = if diagnosis == :all
        nil
      else
        diagnosis
      end
      field = ["monthly", metric, diagnosis_code, gender].compact.join("_")
      where(facility: facility).sum(field).to_i
    end

    def period
      Period.month(month_date)
    end
  end
end
