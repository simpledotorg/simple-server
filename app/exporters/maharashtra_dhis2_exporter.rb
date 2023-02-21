class MaharashtraDHIS2Exporter
  require "dhis2"

  def self.export
    unless Flipper.enabled?(:maharashtra_dhis2_export)
      abort("Maharashtra DHIS2 export is not enabled. Enable the 'maharashtra_dhis2_export' flag in Flipper to enable it.")
    end

    periods = (current_month_period.advance(months: -24)..current_month_period)

    exporter = Dhis2Exporter.new(
      facility_identifiers: FacilityBusinessIdentifier.dhis2_org_unit_id,
      periods: periods,
      data_elements_map: CountryConfig.current.fetch(:dhis2_data_elements)
    )

    exporter.export do |facility_identifier, period|
      repository = Reports::Repository.new(facility_identifier.facility.region, periods: periods)
      slug = facility_identifier.facility.region.slug

      {monthly_registrations_male: repository.monthly_registrations_by_gender.dig(slug, period, "male"),
       monthly_registrations_female: repository.monthly_registrations_by_gender.dig(slug, period, "female"),
       controlled_male: repository.controlled_by_gender.dig(slug, period, "male"),
       controlled_female: repository.controlled_by_gender.dig(slug, period, "female")}
    end
  end

  def current_month_period
    @current_month_period ||= Period.current.previous
  end
end
