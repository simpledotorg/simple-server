namespace :dell_demo do
  NCD_STAGING_URL = 'https://ncd-staging.nhp.gov.in/cphm'
  NCD_STAGING_ENROLLMENT_API = "#{NCD_STAGING_URL}/enrollment/individual"

  desc 'Take a batch of patients from Simple Server
        and push them to the Dell NCD staging server through the Enrollment API'

  task :push_patient_data_to_enrollment_api,
       [:simple_org_name, :number_of_patients] => :environment do |_t, args|

    #
    # Parse args
    #
    abort 'Requires <number_of_patients>' unless args[:number_of_patients].present?
    # abort 'Requires <enrollment_api_auth_token>' unless args[:enrollment_api_auth_token].present?
    number_of_patients = Integer(args[:number_of_patients])
    enrollment_api_auth_token = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX25hbWUiOiJkb2NfMTA4MDExNSIsInNjb3BlIjpbInJlYWQiLCJ3cml0ZSJdLCJpc0xvY2FsUG9ydGFsIjoiZmFsc2UiLCJleHAiOjE1Nzc4MTY3OTEsInVzZXIiOiJkb2NfMTA4MDExNSIsImF1dGhvcml0aWVzIjpbIlNBVkVfTEFCX1JFUVVFU1QiLCJWSUVXX1BIQ19EQVNIQk9BUkRTIiwiQVVUSE9SSVRZX0lOQ0VOVElWRSIsIlZJRVdfQ0FOQ0VSX1BBVElFTlRTIiwiQUREX1BIQ19SRUZFUlJBTCJdLCJqdGkiOiJlZTU0NWZhMy0yMjc5LTQ2MzUtYmEyZC02NjM3YzAzZTEyMWQiLCJjbGllbnRfaWQiOiJOQ0RCcm93c2VyIn0.BpkJQ1gkkxiqn7SLABfBnNESi4T4irk3ZJIyTf1sQizaaiVLcnE0gOKKQWHFaUfpWpOV9MUB_3tHoaaimm6PZe6Lp2Cw5uF9wVvHEQgo9aJ4xPFZkOFQSU_a9Ou0_M6yI58NRPiIPIdLgVdWrDWXsVQlF-8E4g8nfvyS2tQwAtpyRZXEUrr_F1UCwUrIp8zRqw-ULL6d1xvasYqJ08Nml6qRgjjk1t-aL7zTwiC0eemhCI87glLdO3K6bc6_Dkypm-2j01DjncI_PcNJvxgabykrfV5gf6aT3TpBxQTbRA8sW-ae8zWYj4ZhzAiM7mWPMl8BTYCFokD6zzRkLWfmpQ"
    simple_org_name = args[:simple_org_name].presence || 'IHCI'

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

        sub_center_name: "SimpleSubcenter",
        sub_center_id: 10814114,
        village_name: "SimpleVillage",
        village_id: 108000502,
        phc_name: "SimplePHC",
        phc_id: "1080195",
      }

      assumed_default_headers = {
        facility_type: 'PHC',
        facility_type_id: '3200'
      }

      #
      # all the important information in this payload that we can actually populate is bubbled up-top
      # the information that we cannot currently populate and is also optional is left as 'nil'
      #
      enrollment_payload = {
        "individualInfo" =>
          { "name" => patient.full_name,
            "age" => patient.age,
            "gender" => patient.gender.capitalize,
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
              { "subcenterName" => assumed_defaults[:sub_center_name],
                "subcenterId" => assumed_defaults[:sub_center_id],
                "village" => assumed_defaults[:village_name],
                "villageId" => assumed_defaults[:village_id],
                "phc" => assumed_defaults[:phc_name],
                "phcId" => assumed_defaults[:phc_id],
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
            "contactDetail" => nil
          }
      }

      # fire the enrollment API call
      begin
        response = HTTP
                     .headers(assumed_default_headers)
                     .auth("Bearer #{enrollment_api_auth_token}")
                     .post(NCD_STAGING_ENROLLMENT_API, json: enrollment_payload)

        puts response.body
      rescue HTTP::Error => _err
        Rails.logger.info "Could not push patient: #{patient.id} | #{patient.full_name}"
        raise _err
      end
    end
  end
end
