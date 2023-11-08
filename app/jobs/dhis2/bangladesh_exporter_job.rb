module Dhis2
  class BangladeshExporterJob
    include Sidekiq::Job
    sidekiq_options retry: 2
    sidekiq_options queue: :default

    def perform(facility_identifier_id, total_months)
      facility_identifier = FacilityBusinessIdentifier.find(facility_identifier_id)
      periods = Dhis2::Helpers.last_n_month_periods(total_months)
      facility_data = []

      periods.map do |period|
        facility_data_for_period = facility_data_for_period(facility_identifier, period)
        facility_data << Dhis2::Helpers.format_facility_period_data(
          facility_data_for_period,
          facility_identifier,
          period,
          config.fetch(:data_elements_map)
        )
      end

      Dhis2::Helpers.send_data_to_dhis2(facility_data.flatten)
      Rails.logger.info("Dhis2::BangladeshExporterJob for facility identifier #{facility_identifier} succeeded.")
    end

    private

    def facility_data_for_period(facility_identifier, period)
      facility = facility_identifier.facility
      repository = Reports::Repository.new(facility.region, periods: periods)
      slug = facility.region.slug
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

    def config
      {data_elements_map: CountryConfig.dhis2_data_elements.fetch(:dhis2_data_elements)}
    end
  end
end
