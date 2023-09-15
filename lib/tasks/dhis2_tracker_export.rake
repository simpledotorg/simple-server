namespace :dhis2 do
  desc "Export all patients in all facilities to DHIS2"
  task export_tracker_data: :environment do
    errors = []
    facilities = YAML.load_file(ENV.fetch("DHIS2_TRACKER_CONFIG_FILE"))
      .with_indifferent_access
      .fetch(:facilities_to_migrate)

    facilities.map do |facility|
      response = Dhis2TrackerDataExporter.new(facility.slug, facility[:org_unit_id])
        .export_tracked_entities
      puts response
      start = Time.new
      loop do
        status_check_response = RestClient::Request.new(
          method: :get,
          url: response.dig("response", "location"),
          user: "admin",
          password: "district"
        ).execute
        res = JSON.parse(status_check_response)
        break if res.size > 0 && res.first["completed"]
        sleep(5.second)
      end
      puts "Completed Job in #{Time.new - start} seconds"
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

  desc "Export regions as org units to DHIS2"
  task export_regions: :environment do
    Dhis2::RegionsExporter
      .new(Region.find_by(slug: "summit-heart-foundation"), true)
      .export
  end
end
