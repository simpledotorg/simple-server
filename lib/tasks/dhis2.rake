namespace :dhis2 do
  desc "Export aggregate indicators for each facility to DHIS2"
  task export: :environment do
    facility_map = {
      "CHC Chicory Cove" => "SGeL573UZ41",
      "CHC Juniper Overlook" => "d7Yo8u586tS"
    }

    data_elements_map = {
      controlled_patients: "elWGoiZbYCa",
      cumulative_registrations: "oR5QO3WZ7CV",
      cumulative_registrations_3mon_ago: "njezGZZhAHE",
      dead_patients: "O4nEQtNS325",
      ltfu_patients: "EPF0BKHxFm3",
      missed_visits: "krLrdM8K91W",
      registrations: "sURvoNwsSnT",
      uncontrolled_patients: "Di8ckAcPyUT"
    }

    current_period = Period.month("April 2021")

    bulk_data = []

    facility_map.each do |name, org_unit_id|
      facility = Facility.find_by!(name: name)

      report = Reports::RegionService.new(region: facility.region, period: current_period, months: 27).call

      first_period = current_period.advance(months: -21)

      (first_period..current_period).each do |period|
        dhis2_period = period.to_date.strftime("%Y%m")

        controlled_patients = report.controlled_patients[period]
        cumulative_registrations = report.cumulative_registrations[period]
        ltfu_patients = report.ltfu_patients[period]
        missed_visits = report.missed_visits[period]
        registrations = report.registrations[period]
        uncontrolled_patients = report.uncontrolled_patients[period]

        # Get assigned patients from 3 months ago (for control rate indicator)
        reg_3_months_ago = report.cumulative_registrations[period.advance(months: -3)]

        # Calculate dead patients (since we don't store it historically)
        adj_patients = report.adjusted_patient_counts[period]
        dead_patients = reg_3_months_ago - ltfu_patients - adj_patients

        data = {
          controlled_patients: controlled_patients,
          cumulative_registrations: cumulative_registrations,
          cumulative_registrations_3mon_ago: reg_3_months_ago,
          dead_patients: dead_patients,
          ltfu_patients: ltfu_patients,
          missed_visits: missed_visits,
          registrations: registrations,
          uncontrolled_patients: uncontrolled_patients
        }

        data.each do |data_element, value|
          data_element_id = data_elements_map[data_element]

          bulk_data << {
            data_element: data_element_id,
            org_unit: org_unit_id,
            period: dhis2_period,
            value: value
          }
          puts "Adding data for #{facility.name}, #{period}, #{data_element}: #{bulk_data.last}"
        end
      end
    end

    Dhis2.client.data_value_sets.bulk_create(data_values: bulk_data)
  end
end
