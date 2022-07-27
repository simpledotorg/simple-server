class CPHCEnrollment::EnrollmentPayload
  attr_reader :patient, :location_finder, :cphc_facility

  def initialize(patient, location_finder:)
    @patient = patient
    @location_finder = location_finder
  end

  def cphc_location
    simple_facility_hash = location_finder.simple_facility("facility_id" => @patient.assigned_facility.id)
    cphc_location_hash = location_finder.find_cphc_location("facility_name" => simple_facility_hash["facility_name"])
    puts "Found CPHC location for facility_name #{simple_facility_hash["facility_name"]}" if cphc_location_hash
    cphc_location_hash
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

  def as_json
    bp_passport_id = patient.business_identifiers.where(identifier_type: :simple_bp_passport).order(device_created_at: :desc).first.id
    {
      individualInfo: {
        name: patient.full_name,
        birthDate: patient.date_of_birth,
        age: patient.age,
        gender: gender,

        # The enrollment API require patient phone numbers to be 9 digits long
        mobileNumber: patient.phone_numbers.first&.number.delete(" ").reverse[0..9].reverse,
        additionalDetails: {
          enrollmentDate: patient.recorded_at.strftime("%d-%m-%Y"),

          # Consent to get sms from NCD Program
          smsConsentNcd: patient.reminder_consent_granted?, # TODO: Check if we want to send this

          # Consent to get sms from MHealth Program
          smsConsentMProg: false # TODO: Do we have this? Is this always true?
        }
      },
      familyInfo: {
        additionalDetails: {
          idOther: "ihci-simple-patient-bp-passport-id",
          idOtherVal: bp_passport_id
        },
        addressInfo: {
          addressDetails: "Street Details: #{patient.address.street_address}",
          subcenterName: cphc_location["subcenter_name"],
          subcenterId: cphc_location["subcenter_id"],
          village: cphc_location["village_name"],
          villageId: cphc_location["village_id"],
          phc: cphc_location["phc_name"],
          phcId: cphc_location["phc_id"],
          villageOther: nil # TODO: Use if village not present in the cphc facility dump
        }
      }
    }
  end
end
