module Dhis2
  class BangladeshDhis2Exporter
    TOTAL_MONTHS = 24

    def self.export
      FacilityBusinessIdentifier.dhis2_org_unit_id.each do |facility_identifier|
        Dhis2::BangladeshExporterJob.perform_async(facility_identifier.id, TOTAL_MONTHS)
      end
    end
  end
end
