module Reports
  class FacilityStateGroup < Reports::View
    self.table_name = "reporting_facility_state_groups"

    belongs_to :facility

    def self.materialized?
      true
    end
  end
end
