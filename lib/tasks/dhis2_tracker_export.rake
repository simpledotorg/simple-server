namespace :dhis2 do
  desc "Export all patients in all facilities to DHIS2"
  task export_tracker_data: :environment do
    dhis2_facilities = YAML.load_file("config/data/dhis2/tracker/sandbox.yml")
      .with_indifferent_access
      .fetch(:facilities_to_migrate)

    facilities = Facility.all.filter { |f| f.patients.count > 0 }
    total_patients_exported = 0
    export_start_time = Time.new

    loop do
      retries = 1
      max_retries = 10
      facility = facilities.sample

      puts "-----------------------------------------------------"

      response, no_patients = Dhis2TrackerDataExporter.new(facility.slug, dhis2_facilities.sample[:org_unit_id])
        .export_tracked_entities

      total_patients_exported += no_patients
      puts "[#{response["http_status_code"]}] Job: #{response.dig("response", "location")}"

      # Check if Job is complete
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
      rescue RestClient::ExceptionWithResponse => e
        puts e
        sleep(50.second * retries)
        break if retries >= max_retries
      end
      puts "Completed Job in #{(Time.new - start).floor(2)}s"
      time_elapsed = Time.new - export_start_time
      puts "[#{Time.new}] Total Exported Patients: #{total_patients_exported}. Time elapsed: #{time_elapsed.floor(2)}s. ETA: #{(time_elapsed * 1000000 / total_patients_exported / 60 / 60).floor(2)}h"
      next unless response["status"] != "OK"

      puts response
    rescue => e
      puts e
      sleep(5.seconds)
    end
  end
end
