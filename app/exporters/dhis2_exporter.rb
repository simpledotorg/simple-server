class DHIS2Exporter
  require "dhis2"

  def self.export
    new.export
  end

  def initialize
    abort("DHIS2 export not enabled in Flipper") unless Flipper.enabled?(:dhis2_export)

    Dhis2.configure do |config|
      config.url = ENV.fetch("DHIS2_URL")
      config.user = ENV.fetch("DHIS2_USERNAME")
      config.password = ENV.fetch("DHIS2_PASSWORD")
      config.version = ENV.fetch("DHIS2_VERSION")
    end
  end

  def export
    data_elements_map = CountryConfig.current.fetch(:dhis2_data_elements)

    current_month_period = Period.current.previous

    FacilityBusinessIdentifier.dhis2_org_unit_id.each do |facility_identifier|
      facility_bulk_data = []

      facility = facility_identifier.facility
      slug = facility.region.slug
      org_unit_id = facility_identifier.identifier

      range = (current_month_period.advance(months: -24)..current_month_period)

      repository = Reports::Repository.new(facility.region, periods: range)

      range.each do |month_period|
        data = {
          cumulative_assigned: repository.cumulative_assigned_patients[slug][month_period],
          cumulative_assigned_adjusted: repository.adjusted_patients_with_ltfu[slug][month_period],
          controlled: repository.controlled[slug][month_period],
          uncontrolled: repository.uncontrolled[slug][month_period],
          missed_visits: repository.missed_visits[slug][month_period],
          ltfu: repository.ltfu[slug][month_period],
          # Note: dead patients are always the current count due to lack of status timestamps
          dead: facility.assigned_patients.with_hypertension.status_dead.count,
          cumulative_registrations: repository.cumulative_registrations[slug][month_period],
          monthly_registrations: repository.monthly_registrations[slug][month_period]
        }

        data.each do |data_element, value|
          data_element_id = data_elements_map[data_element]

          facility_bulk_data << {
            data_element: data_element_id,
            org_unit: org_unit_id,
            period: reporting_period(month_period),
            value: value
          }
          puts "Adding data for #{facility.name}, #{month_period}, #{data_element}: #{facility_bulk_data.last}"
        end
      end

      pp Dhis2.client.data_value_sets.bulk_create(data_values: facility_bulk_data)
    end
  end

  def reporting_period(month_period)
    if Flipper.enabled?(:dhis2_use_ethiopian_calendar)
      EthiopiaCalendarUtilities.gregorian_month_period_to_ethiopian(month_period).to_dhis2
    else
      month_period.to_s(:dhis2)
    end
  end
end
