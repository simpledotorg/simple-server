class OneOff::CPHCEnrollment::EnrollmentPayload
  attr_reader :patient, :cphc_facility

  def initialize(patient)
    @patient = patient
    @cphc_location = nil
  end

  def cphc_location
    {"district_id" => ENV["CPHC_DISTRICT_ID"],
     "district_name" => ENV["CPHC_DISTRICT_NAME"],
     "taluka_id" => ENV["CPHC_TALUKA_ID"],
     "taluka_name" => ENV["CPHC_TALUKA_NAME"],
     "phc_id" => ENV["CPHC_PHC_ID"],
     "phc_name" => ENV["CPHC_PHC_NAME"],
     "subcenter_id" => ENV["CPHC_SUBCENTER_ID"],
     "subcenter_name" => ENV["CPHC_SUBCENTER_NAME"],
     "village_id" => ENV["CPHC_VILLAGE_ID"],
     "village_name" => ENV["CPHC_VILLAGE_NAME"]}
  end

  def facilities_hashes(file_name)
    CSV.read(file_name, headers: true).map(&:to_h)
  end

  def enrollmentFormId
    SecureRandom.uuid
  end

  def gender
    case patient.gender
    when "male"
      "Male"
    when "female"
      "Female"
    else
      "Other"
    end
  end

  def payload_as_json
    bp_passport_id = patient.business_identifiers.where(identifier_type: :simple_bp_passport).order(device_created_at: :desc).first&.identifier
    phone_number = patient.phone_numbers.first&.number
    {
      individualInfo: {
        name: patient.full_name,
        birthDate: patient.date_of_birth,
        age: patient.age,
        gender: gender,

        # The enrollment API require patient phone numbers to be 10 digits long
        mobileNumber: phone_number && phone_number.delete(" ").reverse[0..9].reverse,
        additionalDetails: {
          enrollmentDate: patient.recorded_at.strftime("%d-%m-%Y"),

          # Consent to get sms from NCD Program
          smsConsentNcd: patient.reminder_consent_granted?,

          # Consent to get sms from MHealth Program
          smsConsentMProg: false
        }
      },
      familyInfo: {
        **bp_passport_info(bp_passport_id),
        addressInfo: {
          addressDetails: "Street Details: #{patient.address.street_address} #{patient.address.village_or_colony}",
          subcenterName: cphc_location["subcenter_name"],
          subcenterId: cphc_location["subcenter_id"],
          village: cphc_location["village_name"],
          villageId: cphc_location["village_id"],
          phc: cphc_location["phc_name"],
          phcId: cphc_location["phc_id"],
          villageOther: nil
        }
      }
    }
  end

  def bp_passport_info(bp_passport_id)
    return {} if bp_passport_id.blank?

    {
      additionalDetails: {
        idOther: "ihci-bp-passport-id",
        idOtherVal: bp_passport_id
      }
    }
  end
end
