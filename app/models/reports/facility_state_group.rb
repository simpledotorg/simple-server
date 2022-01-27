module Reports
  class FacilityStateGroup < Reports::View
    self.table_name = "reporting_facility_state_groups"

    belongs_to :facility

    def self.materialized?
      true
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
