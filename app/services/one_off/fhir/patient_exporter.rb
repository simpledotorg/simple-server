require "fhir_models"

class OneOff::Fhir::PatientExporter
  attr_reader :patient

  def initialize(patient)
    @patient = patient
  end

  def export
    FHIR::Patient.new(
      identifier: [
        FHIR::Identifier.new(
          value: patient.id.to_s
        )
        # TODO: Add patient business identifiers
      ],
      name: [
        FHIR::HumanName.new(
          text: patient.full_name
        )
      ],
      active: patient.status == "active",
      gender: gender,
      birthDate: patient.date_of_birth,
      deceasedBoolean: patient.status == "dead",
      managingOrganization: FHIR::Reference.new(
        reference: FHIR::Organization.new(
          type: "prov",
          identifier: [{
            value: patient.assigned_facility_id
          }]
        )
      ),
      meta: FHIR::Meta.new(
        lastUpdated: patient.updated_at,
        createdAt: patient.recorded_at
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
    unless [:male, :female].include?(patient.gender)
      return "other"
    end
    patient.gender.to_s
  end

  def birth_date
    unless patient.date_of_birth
      patient.age_updated_at - patient.age.years
    end

    patient.date_of_birth
  end
end
