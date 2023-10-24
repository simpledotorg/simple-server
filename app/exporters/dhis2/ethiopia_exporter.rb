class Dhis2::EthiopiaExporter
  PREVIOUS_MONTHS = 24

  def self.export
    facility_identifiers = FacilityBusinessIdentifier.dhis2_org_unit_id
    data_elements_map = CountryConfig.dhis2_data_elements.fetch(:dhis2_data_elements)

    facility_identifiers.map do |facility_identifier|
      Dhis2::EthiopiaExporterJob.perform_async(data_elements_map.stringify_keys, facility_identifier.id, PREVIOUS_MONTHS)
    end
  end
end
