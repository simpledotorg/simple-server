class EthiopiaDhis2ExporterJob
  include Sidekiq::Job

  def perform(facility_identifier, periods)
    ethiopia_exporter = Dhis2::EthiopiaExporter.new
    dhis2_exporter = Dhis2Exporter.new(
      data_elements_map: ethiopia_exporter.data_elements_map
    )
    facility_data = []

    periods.map do |period|
      facility_data_for_period = facility_data_for_period(facility_identifier, period)
      facility_data << dhis2_exporter.format_facility_period_data(
        facility_data_for_period,
        period,
        facility_identifier,
        ethiopia_exporter.data_elements_map
      )
    end

    dhis2_exporter.send_data_to_dhis2(facility_data.flatten)

    Rails.logger.info("EthiopiaDhis2ExporterJob for facility identifier #{facility_identifier} succeeded.")
  end

  def facility_data_for_period(facility_identifier, period)
    region = facility_identifier.facility.region
    {
      htn_controlled: Dhis2::Helpers.htn_controlled(region, period),
      htn_cumulative_assigned: Dhis2::Helpers.htn_cumulative_assigned(region, period),
      htn_cumulative_assigned_adjusted: Dhis2::Helpers.htn_cumulative_assigned_adjusted(region, period),
      htn_cumulative_registrations: Dhis2::Helpers.htn_cumulative_registrations(region, period),
      htn_dead: Dhis2::Helpers.htn_dead(region, period),
      htn_monthly_registrations: Dhis2::Helpers.htn_monthly_registrations(region, period),
      htn_ltfu: Dhis2::Helpers.htn_ltfu(region, period),
      htn_missed_visits: Dhis2::Helpers.htn_missed_visits(region, period),
      htn_uncontrolled: Dhis2::Helpers.htn_uncontrolled(region, period)
    }
  end
end
