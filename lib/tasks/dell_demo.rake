namespace :dell_demo do
  NCD_STAGING_URL = 'https://ncd-staging.nhp.gov.in/cphm'
  NCD_STAGING_ENROLLMENT_API = "#{NCD_STAGING_URL}/enrollment/individual"
  AUTH_TOKEN = 'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX25hbWUiOiJkb2NfMTA4MDExNSIsInNjb3BlIjpbInJlYWQiLCJ3cml0ZSJdLCJpc0xvY2FsUG9ydGFsIjoiZmFsc2UiLCJleHAiOjE1NzYwODY2NjYsInVzZXIiOiJkb2NfMTA4MDExNSIsImF1dGhvcml0aWVzIjpbIlZJRVdfQ0FOQ0VSX1BBVElFTlRTIiwiU0FWRV9MQUJfUkVRVUVTVCIsIlZJRVdfUEhDX0RBU0hCT0FSRFMiLCJBVVRIT1JJVFlfSU5DRU5USVZFIiwiQUREX1BIQ19SRUZFUlJBTCJdLCJqdGkiOiI1YzU4MTgwZC1hYWY4LTRlNzUtYThiNy04OWRjNWRiNzQ2MGYiLCJjbGllbnRfaWQiOiJOQ0RCcm93c2VyIn0.EAxyORaexWvacw-L2TMHm6DTuyvucTumMfxSjwZZE96lfm-0obfgfE6U_6Pn4y_Q0U5hbSDujLlBXvD0mh95gb84tC385WmIXXWjgdOWNXgCHQn6ybT_lJ1t3m-ixgDAqfuB1fDuwT1zWIdCry_R4FNjJ1n8G-xicjPuBOjLgsDDl8ZkyDz-0boi13UUWZD8Egslq28lP9VCt6tT_xREhUrjpdb9wTKB-KqL9sMdlRp973bQADkCriL8NVUdKzbroR1bS77pVnMcr-W7mYw5NTu_a_8reeLBU6BE-BpuMoiKCfchW9nbcXKRDy6gKDh7OCAhlXlG-kxD4VKgdqZo8g'

  desc 'Take a batch of patients from Simple Server
        and push them to the Dell NCD staging server through the Enrollment API'

  task :push_patient_data_to_enrollment_api => :environment do |_t, _args|
    chosen_organization = Organization.find_by_name('IHCI')

    selected_batch_of_patients = Patient
                                   .includes(registration_facility: { facility_group: :organization })
                                   .where(registration_facility:
                                            { facility_groups: { organization: chosen_organization } })
                                   .take(1)

    Rails.logger.info "Batch of patients selected..."
    selected_batch_of_patients.each do |patient|
      Rails.logger.info "#{patient.full_name} | #{patient.age} | #{patient.recorded_at}"

      #
      # these are educated guesses, but by no means indisputable
      #
      assumed_defaults = { marital_status: 'Single',
                           sms_consent_ncd: patient.reminder_consent_granted?,
                           sms_consent_mprog: patient.reminder_consent_granted? }

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

      # fire off the enrollment API call
      begin
        HTTP
          .auth("Bearer #{AUTH_TOKEN}")
          .post(NCD_STAGING_URL, form: enrollment_payload)
      rescue HTTP::Error => _err
        Rails.logger.info "Could not push patient: #{patient.id} | #{patient.full_name}"
        raise HTTPError
      end
    end
  end
end
