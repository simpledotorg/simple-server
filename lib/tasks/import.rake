require "csv"
require "open-uri"

namespace :import do
  desc "Generate encryption key"
  task generate_key: :environment do
    puts SecureRandom.hex(ActiveSupport::MessageEncryptor.key_len / 2)
  end

  desc "Encrypt file/URL and output to STDOUT"
  task encrypt_file: :environment do
    filename = ENV.fetch("FILE")
    crypt = ActiveSupport::MessageEncryptor.new(ENV.fetch("KEY"))

    file_text = open(filename).read
    puts crypt.encrypt_and_sign(file_text)
  end

  desc "Import the Punjab Master Facility Registry"
  task punjab_facilities: :environment do
    filename = ENV.fetch("FILE")
    #crypt = ActiveSupport::MessageEncryptor.new(ENV.fetch("KEY"))

    file_text = open(filename).read
    #decrypted_text = crypt.decrypt_and_verify(file_text)
    decrypted_text = file_text

    line = 1

    csv = CSV.parse(decrypted_text, headers: true) do |row|
      name = row["health_facility_name"]&.strip&.presence
      facility_type = row["health_facility_type"]&.strip&.presence
      address1 = row["health_facility_street_address_line1"]&.strip&.presence
      address2 = row["health_facility_street_address_line2"]&.strip&.presence
      village = row["health_facility_village_name"]&.strip&.presence
      district = row["health_facility_district_name"]&.strip&.presence
      state = row["health_facility_state_name"]&.strip&.presence
      pin = row["health_facility_pincode"]&.strip&.presence
      latitude = row["health_facility_latitude"]&.strip&.presence
      longitude = row["health_facility_longitude"]&.strip&.presence

      address = [address1, address2].compact.join(", ")

      puts "Importing #{line}: name(#{name}) type(#{facility_type}) address(#{address}) village(#{village}) district(#{district}) state(#{state}) latitude(#{latitude}) longitude(#{longitude})"

      Facility.where(name: name, district: district, state: state).first_or_create do |facility|
        facility.facility_type = facility_type
        facility.street_address = [address1, address2].compact.join(', ')
        facility.village_or_colony = village
        facility.country = "India"
        facility.pin = pin
        facility.latitude = latitude
        facility.longitude = longitude
      end

      line += 1
    end

    puts
    puts "Imported #{line - 1} facilities"
  end
end
