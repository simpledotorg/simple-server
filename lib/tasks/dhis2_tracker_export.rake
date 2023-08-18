namespace :dhis2 do
  desc "Export all patients in all facilities to DHIS2"
  task export_tracker_data: :environment do
    facilities = YAML.load_file(Rails.root.join("config/data/dhis2/tracker/local.yml"))
                     .with_indifferent_access
                     .fetch(:facilities_to_migrate)
    facilities.map do |facility|
      Dhis2TrackerDataExporter.new(facility[:facility_slug], facility[:org_unit]).export_tracked_entites
    end
  end
end
