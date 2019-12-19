namespace :dell_demo do
  NCD_STAGING_URL = 'https://ncd-staging.nhp.gov.in/cphm'
  NCD_STAGING_ENROLLMENT_API = "#{NCD_STAGING_URL}/enrollment/individual"

  desc 'Take a batch of patients from Simple Server
        and push them to the Dell NCD staging server through the Enrollment API'

  task :push_patient_data_to_enrollment_api,
       [:number_of_patients, :simple_org_name, :enrollment_api_auth_token] => :environment do |_t, _args|

    #
    # Parse args
    #
    abort 'Requires <number_of_patients>' unless args[:number_of_patients].present?
    abort 'Requires <enrollment_api_auth_token>' unless args[:email].present? && args[:password].present?
    number_of_patients = args[:number_of_patients]
    simple_org_name = args[:simple_org_name].presence || 'IHCI'
    enrollment_api_auth_token = args[:enrollment_api_auth_token]

    #
    # Pull relevant Simple data
    #
    chosen_organization = Organization.find_by_name(simple_org_name)
    selected_batch_of_patients = Patient
                                   .includes(registration_facility: { facility_group: :organization })
                                   .where(registration_facility:
                                            { facility_groups: { organization: chosen_organization } })
                                   .take(number_of_patients)

    #
    # For each patient, fire off the enrollment API calls
    #
    Rails.logger.info "Batch of patients selected..."
    selected_batch_of_patients.each do |patient|
      Rails.logger.info "#{patient.full_name} | #{patient.age} | #{patient.recorded_at}"

      #
      # these are educated guesses, but by no means indisputable
      #
      assumed_defaults = {
        marital_status: 'Single',
        sms_consent_mprog: patient.reminder_consent_granted?,
        sms_consent_ncd: patient.reminder_consent_granted?,
        :sub_center_name => "SimpleSubcenter",
        :sub_center_id => 10814114,
        :village => "SimpleVillage",
        :village_id => 108000502,
        :phc => "SimplePHC",
        :phc_id => "1080195",
      }

      #
      # all the important information in this payload that we can actually populate is bubbled up-top
      # the information that we cannot currently populate and is also optional is left as 'nil'
      #
      enrollment_payload = {
        "individualInfo" =>
          { "name" => patient.full_name,
            "age" => patient.age,
            "gender" => patient.gender,
            "mobileNumber" => patient.phone_numbers.where(phone_type: 'mobile').first,
            "maritalStatus" => assumed_defaults[:marital_status],

            "personPresent" => nil,
            "surname" => nil,
            "fathersOrSpouseName" => nil,
            "healthInsurance" => nil,
            "healthInsuranceDetails" => nil,
            "photo" => "",

            "individualIds" =>
              { "Aadhaar" => nil,
                "HealthId" => nil,
                "Pan" => nil,
                "VoterID" => nil,
                "DrivingLicense" => nil,
                "SECC" => nil,
                "NPR" => nil },

            "additionalDetails" =>
              { "smsConsentNcd" => assumed_defaults[:sms_consent_ncd],
                "smsConsentMProg" => assumed_defaults[:sms_consent_mprog],
                "education" => nil,
                "mobileOwner" => nil,
                "residenceStatus" => nil,
                "caste" => nil,
                "casteOther" => nil,
                "religion" => nil,
                "religionOther" => nil,
                "anmName" => nil }
          },

        "familyInfo" =>
          { "addressInfo" =>
              { "subcenterName" => "SimpleSubcenter",
                "subcenterId" => 10814114,
                "village" => "SimpleVillage",
                "villageId" => 108000502,
                "phc" => "SimplePHC",
                "phcId" => "1080195",
                "landmark" => nil,
                "addressDetails" => nil,
                "villageOther" => nil },

            "additionalDetails" =>
              { "numberid" => nil,
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
                "idOtherVal" => nil },

            "familyHeadName" => nil,
            "contactDetail" => nil }
      }

      # fire the enrollment API call
      begin
        HTTP
          .auth("Bearer #{enrollment_api_auth_token}")
          .post(NCD_STAGING_URL, form: enrollment_payload)
      rescue HTTP::Error => _err
        Rails.logger.info "Could not push patient: #{patient.id} | #{patient.full_name}"
        raise HTTPError
      end
    end
  end
end
