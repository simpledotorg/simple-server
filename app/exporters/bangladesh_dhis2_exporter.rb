class BangladeshDhis2Exporter
  require "dhis2"

  def self.export
    periods = (current_month_period.advance(months: -24)..current_month_period)

    exporter = Dhis2Exporter.new(
      facility_identifiers: FacilityBusinessIdentifier.dhis2_org_unit_id,
      periods: periods,
      data_elements_map: CountryConfig.current.fetch(:dhis2_data_elements)
    )

    exporter.export do |facility_identifier, period|
      repository = Reports::Repository.new(facility_identifier.facility.region, periods: periods)
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

  def self.current_month_period
    @current_month_period ||= Period.current.previous
  end
end
