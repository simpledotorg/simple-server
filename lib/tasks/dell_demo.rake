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

  desc "Import CPHC PHCs and Subcenters"
  task :import_cphc_phc_and_subcenter, [:filename, :sheet, :district_id] => :environment do |_t, args|
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
        mapping = CphcFacilityMapping.create(row)
        if mapping.present?
          CphcFacility.create_phc_from_mapping(mapping)
          CphcFacility.create_subcenter_from_mapping(mapping)
        end
      end
    end

    puts "Finished importing PHCs and Subcenters"
  end

  desc "Import CPHC CHCs and DHs"
  task :import_cphc_chc_and_dh, [:filename] => :environment do |_t, args|
    xlsx = Roo::Spreadsheet.open(args[:filename])

    sheet = xlsx.sheet(0)

    headers = {
      cphc_facility_id: "hospital_id",
      cphc_facility_name: "hospital_name",
      cphc_facility_type_id: "facilityTypeId",
      cphc_user_id: "UserId",
      cphc_district_id: "district_id",
      cphc_district_name: "District Name",
      cphc_taluka_id: "Taluk ID",
      cphc_taluka_name: "Taluk Name",
      cphc_phc_id: "PHC ID",
      cphc_phc_name: "PHC Name",
      cphc_subcenter_id: "SC ID",
      cphc_subcenter_name: "SC Name",
      cphc_village_id: "Village ID",
      cphc_village_name: "Village Name"
    }

    sheet.each(headers) do |row|
      if row[:cphc_facility_type_id].to_i == OneOff::CphcEnrollment::FACILITY_TYPE_ID["CHC"]
        CphcFacility.create_chc_from_row(row)
      elsif row[:cphc_facility_type_id].to_i == OneOff::CphcEnrollment::FACILITY_TYPE_ID["DH"]
        CphcFacility.create_dh_from_row(row)
      end
    end

    puts "Finished importing CHC and DHs"
  end

  desc "Map CPHC facilities of a given size"
  task :map_cphc_facilities, [:district, :facility_size] => :environment do |_t, args|
    facility_types = {
      community: "SUBCENTER",
      small: "PHC",
      medium: "CHC",
      large: "DH"
    }.with_indifferent_access

    district = args[:district]
    facility_size = args[:facility_size]

    Facility.where(district: district)
      .left_outer_joins(:cphc_facility)
      .where(cphc_facilities: {cphc_facility_id: nil})
      .where(facility_size: facility_size)
      .order(:name)
      .each do |facility|
      potential_mappings =
        CphcFacility
          .search_by_facility_name(facility.name)
          .where(cphc_facility_type: facility_types[facility_size])
          .search_by_region(district)
          .where(facility_id: nil)

      next puts("No Mappings | Block: #{facility.block} | Facility: #{facility.name} \n".red) if potential_mappings.empty?

      puts "Potential Mappings | Block: #{facility.block} | Type: #{facility.facility_type} | Facility: #{facility.name}".green

      puts "\n"
      tp potential_mappings,
        {id: {width: 37}},
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
          mapping.update!(facility_id: facility.id)
          CphcCreateUserJob.perform_async(facility.id)
          break
        end

        if input.size == 36
          jump_to_id = input.to_i
        end
      end
    end
  end

  desc "Import manually mapped facilties"
  task :import_manually_mapped_facilities, [:cphc_facility_mappings, :simple_to_cphc_mapping] => :environment do |t, _args|
    cphc_facility_mappings = Roo::Spreadsheet.open(args[:cphc_facility_mappings]).sheet(0)
    simple_to_cphc_mapping = Roo::Spreadsheet.open(args[:simple_to_cphc_mapping]).sheet(0)

    cphc_facility_mappings.each({
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
    }) do |row|
      mapping = CphcFacilityMapping.create(row)
      if mapping.present?
        CphcFacility.create_phc_from_mapping(mapping)
        CphcFacility.create_subcenter_from_mapping(mapping)
      end
    end

    simple_to_cphc_mapping.each({
      state_name: "state_name",
      district_name: "district_name",
      block_name: "block_name",
      facility_name: "facility_name",
      cphc_facility_id: "CPHC Facility ID"
    }) do |row|
      facility = Facility.find_by!(state: row[:state_name], district: row[:district_name], name: row[:facility_name])
      mapping = CphcFacility.find_by!(cphc_facility_id: row[:cphc_facility_id])
      if mapping.facility_id.present?
        puts "CPHC facility #{mapping.cphc_facility_id} #{mapping.cphc_facility_name} is already mapped to #{mapping.facility.name}"
      else
        mapping.update!(facility_id: facility.id)
        CphcCreateUserJob.perform_async(facility.id)
      end
    end

    puts "Finished importing manually mapped facilities"
  end
end
