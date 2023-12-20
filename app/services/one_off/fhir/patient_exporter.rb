require "fhir_models"

class OneOff::Fhir::PatientExporter
  attr_reader :patient

  def initialize(patient)
    @patient = patient
  end

  def patient_identifiers
    identifiers = [
      FHIR::Identifier.new(
        value: patient.id,
        use: "official"
      )
    ]
    patient.business_identifiers.simple_bp_passport.each do |identifier|
      identifiers << FHIR::Identifier.new(
        value: identifier.identifier,
        use: "secondary"
      )
    end
    identifiers
  end

  def export
    FHIR::Patient.new(
      identifier: patient_identifiers,
      name: [
        FHIR::HumanName.new(
          text: patient.full_name
        )
      ],
      active: patient.status == "active",
      gender: gender,
      birthDate: birth_date.iso8601,
      deceasedBoolean: patient.status == "dead",
      managingOrganization: FHIR::Reference.new(
        identifier: FHIR::Identifier.new(
          value: patient.assigned_facility_id
        )
      ),
      meta: FHIR::Meta.new(
        lastUpdated: patient.updated_at.iso8601,
        createdAt: patient.recorded_at.iso8601
      ),
      telecom: patient.phone_numbers.map do |phone_number|
        FHIR::ContactPoint.new(
          value: phone_number.number,
          use: "mobile"
        )
      end,
      address: FHIR::Address.new(
        line: patient.address.street_address,
        city: patient.address.village_or_colony,
        district: patient.address.district,
        state: patient.address.state,
        country: patient.address.country,
        postalCode: patient.address.pin
      )
    )
  end

  def gender
    return "other" unless ["male", "female"].include?(patient.gender)

    patient.gender
  end

  def birth_date
    return patient.age_updated_at - patient.age.years unless patient.date_of_birth

    patient.date_of_birth
  end
end
