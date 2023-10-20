class Dhis2::EthiopiaExporter
  attr_reader :data_elements_map, :periods, :facility_identifiers

  PREVIOUS_MONTHS = 24

  def initialize
    current_month_period = Dhis2::Helpers.current_month_period
    @periods = (current_month_period.advance(months: -PREVIOUS_MONTHS)..current_month_period)
    @facility_identifiers = FacilityBusinessIdentifier.dhis2_org_unit_id
    @data_elements_map = CountryConfig.dhis2_data_elements.fetch(:dhis2_data_elements)
  end

  def export
    @facility_identifiers.map do |facility_identifier|
      EthiopiaDhis2ExporterJob.perform_async(facility_identifier, @periods)
    end
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

  def self.export
    current_month_period = Dhis2::Helpers.current_month_period
    periods = (current_month_period.advance(months: -PREVIOUS_MONTHS)..current_month_period)

    exporter = Dhis2Exporter.new(
      facility_identifiers: FacilityBusinessIdentifier.dhis2_org_unit_id,
      periods: periods,
      data_elements_map: CountryConfig.dhis2_data_elements.fetch(:dhis2_data_elements)
    )

    exporter.export do |facility_identifier, period|
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
end
