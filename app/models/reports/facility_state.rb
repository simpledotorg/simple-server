module Reports
  class FacilityState < Matview
    self.table_name = "reporting_facility_states"
    belongs_to :facility
  end
end
