class OneOff::CphcEnrollment::EnrollmentPayload
  attr_reader :patient, :cphc_facility, :cphc_location

  UNACCEPTED_CHARACTERS = [("0".."9").to_a, ["-", ",", "/", "%", "$", "#"]].flatten

  def initialize(patient, cphc_location)
    @patient = patient
    @cphc_location = cphc_location
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

  def payload
    bp_passport_id = patient
      .business_identifiers
      .where(identifier_type: :simple_bp_passport)
      .order(device_created_at: :desc)
      .first&.identifier

    full_name = patient.full_name.chars.reject { |c| UNACCEPTED_CHARACTERS.include?(c) }.join
    phone_number = patient.phone_numbers.first&.number
    individual_info = {
      name: full_name,
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
    }

    address_info = {
      addressDetails: "Street Details: #{patient.address.street_address} #{patient.address.village_or_colony}",
      subcenterName: cphc_location["subcenter_name"],
      subcenterId: cphc_location["subcenter_id"],
      phc: cphc_location["phc_name"],
      phcId: cphc_location["phc_id"]
    }

    address_info["villageId"] = cphc_location["village_id"]

    if cphc_location["village_name"] == "Other"
      address_info["villageOther"] = patient.address.village_or_colony
    else
      address_info["village"] = cphc_location["village_name"]
    end

    family_info = {
      "addressInfo" => address_info
    }

    if bp_passport_id.present?
      family_info["additionalDetails"] = {
        idOther: "ihci-bp-passport-id",
        idOtherVal: bp_passport_id
      }
    end

    {
      individualInfo: individual_info,
      familyInfo: family_info
    }
  end
end
