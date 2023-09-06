namespace :dhis2 do
  desc "Export all patients in all facilities to DHIS2"
  task export_tracker_data: :environment do
    errors = []
    facilities = YAML.load_file(ENV.fetch("DHIS2_TRACKER_CONFIG_FILE"))
      .with_indifferent_access
      .fetch(:facilities_to_migrate)

    facilities.map do |facility|
      response = Dhis2TrackerDataExporter.new(facility[:facility_slug], facility[:org_unit_id])
        .export_tracked_entities
      puts response
      next unless response["status"] != "OK"
      errors.append(
        {
          org_unit_id: facility[:org_unit_id],
          facility_slug: facility[:facility_slug],
          error: response
        }
      )
    end
    puts "errors: ", errors unless errors.empty?
  end
end
