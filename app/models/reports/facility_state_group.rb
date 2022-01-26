module Reports
  class FacilityStateGroup < Reports::View
    self.table_name = "reporting_facility_state_groups"

    belongs_to :facility

    def self.materialized?
      true
    end

    def self.total_registrations(facility, diagnosis, gender)
      field = "monthly_registrations_#{diagnosis}_#{gender}"
      where(facility: facility).sum(field).to_i
    end

    def self.total_follow_ups(facility, diagnosis, gender)
      field = "monthly_follow_ups_#{diagnosis}_#{gender}"
      where(facility: facility).sum(field).to_i
    end
  end
end
