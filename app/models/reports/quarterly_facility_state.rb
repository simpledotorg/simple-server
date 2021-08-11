module Reports
  class QuarterlyFacilityState < Matview
    self.table_name = "reporting_quarterly_facility_states"
    belongs_to :facility
  end
end
