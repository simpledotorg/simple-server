module Reports
  class QuarterlyFacilityState < Reports::View
    self.table_name = "reporting_quarterly_facility_states"
    belongs_to :facility

    def self.materialized?
      true
    end

    def period
      @period ||= Period.quarter(month_date)
    end
  end
end
