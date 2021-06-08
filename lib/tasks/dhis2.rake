namespace :dhis2 do
  desc "Export aggregate indicators for each facility to DHIS2"
  task export: :environment do
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

    FacilityBusinessIdentifier.where(identifier_type: "dhis2_org_unit_id").each do |facility_identifier|
      facility = facility_identifier.facility
      slug = facility.region.slug
      org_unit_id = facility_identifier.identifier

      range = (current_period.advance(months: -24)..current_period)
      # report = Reports::RegionService.new(region: facility.region, period: current_period, months: 27).call
      repository = Reports::Repository(facility.region, periods: range)

      first_period = current_period.advance(months: -21)

      (first_period..current_period).each do |period|
        dhis2_period = period.to_date.strftime("%Y%m")

        controlled_patients = repository.controlled_patients_count[slug][period]
        uncontrolled_patients = repository.uncontrolled_patients_count[slug][period]
        cumulative_registrations = repository.cumulative_registrations[slug][period]
        ltfu_patients = repository.ltfu_counts[slug][period]
        missed_visits = repository.missed_visits[slug][period]
        registrations = repository.registrations[slug][period]

        # Get assigned patients from 3 months ago (for control rate indicator)
        reg_3_months_ago = repository.adjusted_patient_counts_with_ltfu[slug][period]

        # Calculate dead patients (since we don't store it historically)
        dead_patients = facility.with_hypertension.assigend_patients.status_dead.count

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

    puts bulk_data

    #Dhis2.client.data_value_sets.bulk_create(data_values: bulk_data)
  end
end
