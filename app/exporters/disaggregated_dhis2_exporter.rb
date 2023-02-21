class DisaggregatedDhis2Exporter
  def self.export
    exporter = Dhis2Exporter.new(
      facility_identifiers: FacilityBusinessIdentifier.dhis2_org_unit_id,
      periods: (current_month_period.advance(months: -24)..current_month_period),
      data_elements_map: CountryConfig.current.fetch(:dhis2_data_elements)
    )
    exporter.export do |facility_identifier, period|
    end
  end
end
