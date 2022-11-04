namespace :dell_demo do
  desc 'Take a batch of patients from Simple Server
        and push them to the Dell NCD staging server through the Enrollment API'

  task :push_patient_data_to_enrollment_api,
    [:simple_org_name, :number_of_patients] => :environment do |_t, args|
    #
    # Only print on console
    #
    logger = Logger.new($stdout)

    #
    # Parse args
    #
    abort "Requires <number_of_patients>" unless args[:number_of_patients].present?
    unless ENV["AUTH_TOKEN"].present?
      abort <<~NOTE
        Requires ENV['AUTH_TOKEN']

        This auth-token is currently not straightforward to acquire:

        * Login to https://ncd-staging.nhp.gov.in/#/portal/enrollment
        * Enroll dummy patient
        * Check the network tab and look at the request headers for the `addScreening` POST request
        * Note down the Authorization header (bearer token)
        * Pass that into the ENV variable.
      NOTE

    end

    number_of_patients = Integer(args[:number_of_patients])
    enrollment_api_auth_token = ENV["AUTH_TOKEN"]
    simple_org_name = args[:simple_org_name].presence || "IHCI"

    #
    # Pull relevant Simple data
    #
    chosen_organization = Organization.find_by_name(simple_org_name)
    selected_batch_of_patients = Patient
      .includes(registration_facility: {facility_group: :organization})
      .where(registration_facility:
                                            {facility_groups: {organization: chosen_organization}})
      .take(number_of_patients)

    #
    # For each patient, fire off the enrollment API calls
    #
    logger.info "Batch of patients selected..."
    logger.info "[Patient details] ==> Individual Enrollment ID (Dell ID)"

    selected_batch_of_patients.each do |patient|
      log_patient = "[#{patient.full_name} | #{patient.age} | #{patient.recorded_at}]"

      #
      # these are educated guesses, but by no means indisputable
      #
      assumed_defaults = {
        marital_status: "Single",

        sms_consent_mprog: patient.reminder_consent_granted?,
        sms_consent_ncd: patient.reminder_consent_granted?,

        sub_center_name: "SimpleSubcenter",
        sub_center_id: 10814114,
        village_name: "SimpleVillage",
        village_id: 108000502,
        phc_name: "SimplePHC",
        phc_id: "1080195"
      }

      assumed_default_headers = {
        "facilityType" => "PHC",
        "facilityTypeId" => "3200"
      }

      #
      # all the important information in this payload that we can actually populate is bubbled up-top
      # the information that we cannot currently populate and is also optional is left as 'nil'
      #
      enrollment_payload = {
        "individualInfo" =>
          {"name" => patient.full_name,
           "age" => patient.age,
           "gender" => patient.gender.capitalize,
           "mobileNumber" => patient.phone_numbers.where(phone_type: "mobile").first,
           "maritalStatus" => assumed_defaults[:marital_status],

           "personPresent" => nil,
           "surname" => nil,
           "fathersOrSpouseName" => nil,
           "healthInsurance" => nil,
           "healthInsuranceDetails" => nil,
           "photo" => "",

           "individualIds" =>
              {"Aadhaar" => nil,
               "HealthId" => nil,
               "Pan" => nil,
               "VoterID" => nil,
               "DrivingLicense" => nil,
               "SECC" => nil,
               "NPR" => nil},

           "additionalDetails" =>
              {"smsConsentNcd" => assumed_defaults[:sms_consent_ncd],
               "smsConsentMProg" => assumed_defaults[:sms_consent_mprog],
               "education" => nil,
               "mobileOwner" => nil,
               "residenceStatus" => nil,
               "caste" => nil,
               "casteOther" => nil,
               "religion" => nil,
               "religionOther" => nil,
               "anmName" => nil}},

        "familyInfo" =>
          {"addressInfo" =>
              {"subcenterName" => assumed_defaults[:sub_center_name],
               "subcenterId" => assumed_defaults[:sub_center_id],
               "village" => assumed_defaults[:village_name],
               "villageId" => assumed_defaults[:village_id],
               "phc" => assumed_defaults[:phc_name],
               "phcId" => assumed_defaults[:phc_id],
               "landmark" => nil,
               "addressDetails" => nil,
               "villageOther" => nil},

           "additionalDetails" =>
              {"numberid" => nil,
               "ASHA" => nil,
               "hamlet" => nil,
               "house" => nil,
               "hOther" => nil,
               "toilet" => nil,
               "tOther" => nil,
               "water" => nil,
               "wOther" => nil,
               "electricity" => nil,
               "eOther" => nil,
               "vehicle" => nil,
               "vOther" => nil,
               "fuel" => nil,
               "fOther" => nil,
               "apl" => nil,
               "income" => nil,
               "hsOwner" => nil,
               "ration" => nil,
               "idOther" => nil,
               "idOtherVal" => nil},

           "familyHeadName" => nil,
           "contactDetail" => nil}
      }

      # fire the enrollment API call
      begin
        ncd_staging_enrollment_api = "https://ncd-staging.nhp.gov.in/cphm/enrollment/individual"

        response = HTTP
          .headers(assumed_default_headers)
          .auth("Bearer #{enrollment_api_auth_token}")
          .post(ncd_staging_enrollment_api, json: enrollment_payload)

        response_body = JSON.parse(response.body, symbolize_names: true)
        logger.info "#{log_patient} ==> #{response_body[:individualId]}"
      rescue HTTP::Error => err
        logger.info "Could not push patient: #{patient.id} | #{patient.full_name}"
        raise err
      end
    end
  end

  desc "Import CPHC Facilities"
  task :import_cphc_facilities, [:filename, :sheet, :district_id] => :environment do |_t, args|
    xlsx = Roo::Spreadsheet.open(args[:filename])

    sheet = xlsx.sheet(args[:sheet])

    headers = {
      cphc_state_id: "state_id",
      cphc_state_name: "state_name",
      cphc_district_id: "district_id",
      cphc_district_name: "district_name",
      cphc_taluka_id: "taluka_id",
      cphc_taluka_name: "taluka_name",
      cphc_phc_id: "phc_id",
      cphc_phc_name: "phc_name",
      cphc_subcenter_id: "subcenter_id",
      cphc_subcenter_name: "subcenter_name",
      cphc_village_id: "village_id",
      cphc_village_name: "village_name"
    }

    sheet.each(headers) do |row|
      if row[:cphc_district_id].to_s == args[:district_id]
        CphcFacilityMapping.create(row)
      end
    end

    puts "Finished importing facilities"
  end

  desc "Map CPHC Facilities"
  task :map_cphc_facilities, [:district] => :environment do |_t, args|
    district = args[:district]
    Facility.where(district: district)
      .left_outer_joins(:cphc_facility_mappings)
      .where(cphc_facility_mappings: {cphc_phc_id: nil})
      .order(:name)
      .each do |facility|
      potential_mappings = CphcFacilityMapping.where(facility: nil)
        .search_by_facility(facility.name)
        .search_by_region(district)
        .uniq(&:cphc_phc_name)

      next puts("No Mappings | Block: #{facility.block} | Facility: #{facility.name} \n".red) if potential_mappings.empty?

      puts "Potential Mappings | Block: #{facility.block} | Facility: #{facility.name}".green

      puts "\n"
      tp potential_mappings,
        :id,
        :cphc_district_name,
        :cphc_taluka_name,
        :cphc_subcenter_name,
        :cphc_phc_name

      puts "\n"
      jump_to_id = nil
      potential_mappings.each do |mapping|
        if jump_to_id.present? && mapping.id != jump_to_id
          next
        end
        jump_to_id = nil

        print "Map #{facility.name} to #{mapping.cphc_phc_name}? [(y)es, (n)o, (a)ll (s)kip, (id)jump] "
        input = $stdin.gets.strip
        puts "\n"

        if input == "s"
          break
        end

        if input == "y"
          CphcFacilityMapping.where(cphc_phc_name: mapping.cphc_phc_name).update(facility: facility)
        end

        if input == "a"
          potential_mappings.update(facility: facility)
          break
        end

        if input.to_i != 0
          jump_to_id = input.to_i
        end
      end
    end
  end

  desc "Map CPHC Subcenters"
  task :map_cphc_subcenters, [:district] => :environment do |_t, args|
    district = args[:district]
    Facility.where(district: district)
            .left_outer_joins(:cphc_facilities)
            .where(cphc_facilities: {cphc_facility_id: nil})
            .order(:name)
            .reject { |facility| facility.name.starts_with?(/CHC|PHC|UPHC|UCHC|DH /)}
            .each do |facility|
      potential_mappings =
        CphcFacility
          .search_by_subcenter(facility.name)
          .search_by_region(district)
          .where(facility_id: nil)

      next puts("No Mappings | Block: #{facility.block} | Facility: #{facility.name} \n".red) if potential_mappings.empty?

      puts "Potential Mappings | Block: #{facility.block} | Facility: #{facility.name}".green

      puts "\n"
      tp potential_mappings,
         :id,
         :cphc_district_name,
         :cphc_taluka_name,
         :cphc_facility_name

      puts "\n"
      jump_to_id = nil
      potential_mappings.each do |mapping|
        if jump_to_id.present? && mapping.id != jump_to_id
          next
        end
        jump_to_id = nil

        print "Map #{facility.name} to #{mapping.cphc_facility_name}? [(y)es, (n)o, (a)ll (s)kip, (id)jump] "
        input = $stdin.gets.strip
        puts "\n"

        if input == "s"
          break
        end

        if input == "y"
          mapping.update!(facility_id: mapping.facility_id)
        end

        if input.to_i != 0
          jump_to_id = input.to_i
        end
      end
    end
  end
end
