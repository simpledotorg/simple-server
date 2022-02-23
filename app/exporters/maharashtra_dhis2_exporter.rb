class MaharashtraDHIS2Exporter
  require "dhis2"

  def self.export
    new.export
  end

  def initialize
    abort(
      "Maharashtra DHIS2 export is not enabled. Enable the 'maharashtra_dhis2_export' flag in Flipper to enable it."
    ) unless Flipper.enabled?(:maharashtra_dhis2_export)

    Dhis2.configure do |config|
      config.url = ENV.fetch("DHIS2_URL")
      config.user = ENV.fetch("DHIS2_USERNAME")
      config.password = ENV.fetch("DHIS2_PASSWORD")
      config.version = ENV.fetch("DHIS2_VERSION")
    end
  end

  def export
    FacilityBusinessIdentifier.dhis2_org_unit_id.each do |facility_identifier|
      pp Dhis2.client.data_value_sets.bulk_create(data_values: facility_bulk_data(facility_identifier))
    end
  end

  def facility_bulk_data(facility_identifier)
    data_elements_map = CountryConfig.current.fetch(:maharashtra_dhis2_data_elements)

    current_month_period = Period.current.previous

    bulk_data = []
    facility = facility_identifier.facility
    slug = facility.region.slug
    org_unit_id = facility_identifier.identifier

    range = (current_month_period.advance(months: -24)..current_month_period)

    repository = Reports::Repository.new(facility.region, periods: range)

    binding.pry
    range.each do |month_period|
      data = {
        monthly_registrations_male: repository.monthly_registrations_by_gender[slug][month_period]["male"],
        monthly_registrations_female: repository.monthly_registrations_by_gender[slug][month_period]["female"]
      }

      data.each do |data_element, value|
        data_element_id, disaggregation_id = data_elements_map[data_element].split(".")

        bulk_data << {
          data_element: data_element_id,
          org_unit: org_unit_id,
          category_option_combo: disaggregation_id,
          period: reporting_period(month_period),
          value: value
        }
        puts "Adding data for #{facility.name}, #{month_period}, #{data_element}: #{bulk_data.last}"
      end
    end

    bulk_data
  end

  def reporting_period(month_period)
    if Flipper.enabled?(:dhis2_use_ethiopian_calendar)
      EthiopiaCalendarUtilities.gregorian_month_period_to_ethiopian(month_period).to_s(:dhis2)
    else
      month_period.to_s(:dhis2)
    end
  end
end
