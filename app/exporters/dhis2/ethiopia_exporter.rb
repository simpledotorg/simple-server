class Dhis2::EthiopiaExporter
  PREVIOUS_MONTHS = 24

  def self.export
    current_month_period = Dhis2::Helpers.current_month_period
    periods = (current_month_period.advance(months: -PREVIOUS_MONTHS)..current_month_period)
    facility_identifiers = FacilityBusinessIdentifier.dhis2_org_unit_id
    data_elements_map = CountryConfig.dhis2_data_elements.fetch(:dhis2_data_elements)

    facility_identifiers.map do |facility_identifier|
      Dhis2::EthiopiaExporterJob.perform_async(data_elements_map, facility_identifier, periods)
    end
  end
end
