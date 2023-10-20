class EthiopiaDhis2ExporterJob
  include Sidekiq::Job

  def perform(facility_identifier, periods)
    ethiopia_exporter = Dhis2::EthiopiaExporter.new
    dhis2_exporter = Dhis2Exporter.new(
      data_elements_map: ethiopia_exporter.data_elements_map
    )
    facility_data = []

    periods.map do |period|
      facility_data_for_period = ethiopia_exporter.facility_data_for_period(facility_identifier, period)
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
end
