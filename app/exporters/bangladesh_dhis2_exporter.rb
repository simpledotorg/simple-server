class BangladeshDhis2Exporter
  def self.export
    periods = Dhis2::Helpers.last_n_month_periods(24)

    exporter = Dhis2Exporter.new(
      facility_identifiers: FacilityBusinessIdentifier.dhis2_org_unit_id,
      periods: periods,
      data_elements_map: CountryConfig.dhis2_data_elements.fetch(:dhis2_data_elements)
    )

    exporter.export do |facility_identifier, period|
      repository = Reports::Repository.new(facility_identifier.facility.region, periods: periods)
      facility = facility_identifier.facility
      slug = facility_identifier.facility.region.slug
      {
        cumulative_assigned: repository.cumulative_assigned_patients[slug][period],
        cumulative_assigned_adjusted: repository.adjusted_patients_with_ltfu[slug][period],
        controlled: repository.controlled[slug][period],
        uncontrolled: repository.uncontrolled[slug][period],
        missed_visits: repository.missed_visits[slug][period],
        ltfu: repository.ltfu[slug][period],
        # NOTE: dead patients are always the current count due to lack of status timestamps
        dead: facility.assigned_patients.with_hypertension.status_dead.count,
        cumulative_registrations: repository.cumulative_registrations[slug][period],
        monthly_registrations: repository.monthly_registrations[slug][period]
      }
    end
  end
end
