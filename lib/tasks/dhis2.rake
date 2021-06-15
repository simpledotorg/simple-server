require "dhis2"

namespace :dhis2 do
  desc "Export aggregate indicators for each facility to DHIS2"
  task export: :environment do
    # These are hardcoded for dhis2.bd.simple.org for now;
    # future iterations will move this to a config
    data_elements_map = {
      cumulative_assigned: "cc2oSjEbiqv",
      cumulative_assigned_adjusted: "jQBsCW7wjqx",
      controlled: "ItViYyHGgZf",
      uncontrolled: "IH0SueuKSWe",
      missed_visits: "N7rI9y9Kywp",
      ltfu: "nso1TSN7ukq",
      dead: "Qf8Wq8u6AkK",
      cumulative_registrations: "BK2KRHKcTtU",
      monthly_registrations: "GxLDDKPxjxx"
    }

    current_period = Period.current.previous

    FacilityBusinessIdentifier.dhis2_org_unit_id.each do |facility_identifier|
      facility_bulk_data = []

      facility = facility_identifier.facility
      slug = facility.region.slug
      org_unit_id = facility_identifier.identifier

      range = (current_period.advance(months: -24)..current_period)

      repository = Reports::Repository.new(facility.region, periods: range)

      range.each do |period|
        dhis2_period = period.to_date.strftime("%Y%m")

        data = {
          cumulative_assigned: repository.cumulative_assigned_patients[slug][period],
          cumulative_assigned_adjusted: repository.adjusted_patients_with_ltfu[slug][period],
          controlled: repository.controlled[slug][period],
          uncontrolled: repository.uncontrolled[slug][period],
          missed_visits: repository.missed_visits[slug][period],
          ltfu: repository.ltfu[slug][period],
          # Note: dead patients are always the current count due to lack of status timestamps
          dead: facility.assigned_patients.with_hypertension.status_dead.count,
          cumulative_registrations: repository.cumulative_registrations[slug][period],
          monthly_registrations: repository.monthly_registrations[slug][period]
        }

        data.each do |data_element, value|
          data_element_id = data_elements_map[data_element]

          facility_bulk_data << {
            data_element: data_element_id,
            org_unit: org_unit_id,
            period: dhis2_period,
            value: value
          }
          puts "Adding data for #{facility.name}, #{period}, #{data_element}: #{facility_bulk_data.last}"
        end
      end

      puts Dhis2.client.data_value_sets.bulk_create(data_values: facility_bulk_data)
    end
  end
end
