class Dhis2::EthiopiaExporter
  PREVIOUS_MONTHS = 24

  def self.export
    FacilityBusinessIdentifier.dhis2_org_unit_id.each do |facility_identifier|
      Dhis2::EthiopiaExporterJob.perform_async(facility_identifier.id, PREVIOUS_MONTHS)
    end
  end
end
