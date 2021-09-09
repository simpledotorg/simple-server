module Reports
  class PatientFollowUp < Reports::View
    self.table_name = "reporting_patient_follow_ups"
    belongs_to :patient
    belongs_to :facility, class_name: "::Facility"
    belongs_to :user

    def self.for_region(region_or_source)
      region = region_or_source.region
      facility_ids = region.facility_ids
      where(facility_id: facility_ids)
    end

    def self.materialized?
      true
    end
  end
end
