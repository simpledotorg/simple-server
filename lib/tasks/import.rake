require 'csv'
namespace :import do
  desc 'Import facilites from CSV; Example: rake "bulk_upload:facilities_from_csv[path/to/file]"'
  task :facilities_from_csv, [:facilities_file] => :environment do |_t, args|
    facilities_file = args.facilities_file
    created_facilities = 0
    facilities_csv = open(facilities_file)
    CSV.parse(facilities_csv, headers: true) do |row|
      facility_attributes = {
        name: row['name'],
        facility_type: row['facility_type'],
        street_address: row['street_address'],
        village_or_colony: row['village_or_colony'],
        district: row['district'],
        state: row['state'],
        country: row['country'],
        pin: row['pin'],
        latitude: row['latitude'],
        longitude: row['longitude']
      }
      existing_facility = Facility.find_by(name: facility_attributes[:name], district: facility_attributes[:district])
      if existing_facility.present?
        puts "Skipping existing facility: #{facility_attributes[:name]}"
      else
        Facility.create(facility_attributes)
        created_facilities += 1
      end
    end
    puts "Created #{created_facilities} facilities"
  end
end
