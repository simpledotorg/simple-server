require "fhir_models"

module OneOff
  module Opensrp
    class PatientExporter
      attr_reader :patient

      def initialize(patient, opensrp_mapping)
        @patient = patient
        @opensrp_ids = opensrp_mapping[@patient.assigned_facility_id]
      end

      def export
        FHIR::Patient.new(
          id: patient.id,
          identifier: patient_identifiers,
          name: [
            FHIR::HumanName.new(
              use: "official",
              given: patient.full_name.split
            )
          ],
          active: patient.status_active?,
          gender: gender,
          birthDate: birth_date.iso8601,
          deceased: patient.status_dead?,
          managingOrganization: FHIR::Reference.new(
            reference: "Organization/#{opensrp_ids[:organization_id]}"
          ),
          meta: meta,
          telecom: patient.phone_numbers.map do |phone_number|
            FHIR::ContactPoint.new(
              system: "phone",
              value: phone_number.number,
              use: "mobile"
            )
          end,
          address: FHIR::Address.new(
            line: [patient.address.street_address],
            city: patient.address.village_or_colony,
            district: patient.address.district,
            state: patient.address.state,
            country: patient.address.country,
            postalCode: patient.address.pin,
            use: "home",
            type: "physical",
            text: "#{patient.address.street_address} (#{patient.address.village_or_colony}), [No GND Registered]"
          ),
          generalPractitioner: [
            FHIR::Reference.new(reference: "Practitioner/#{opensrp_ids[:practitioner_id]}")
          ],
          # NOTE: these are hardcoded for now, since only Sri Lanka needs this script.
          communication: [{
            language: FHIR::CodeableConcept.new(
              coding: [
                FHIR::Coding.new(
                  system: "urn:ietf:bcp:47",
                  code: "si",
                  display: "Sinhala"
                )
              ],
              text: "Sinhala"
            )
          }]
        )
      end

      def patient_identifiers
        identifiers = [
          FHIR::Identifier.new(
            value: patient.id,
            use: "official"
          )
        ]
        patient.business_identifiers.sri_lanka_personal_health_number.each do |identifier|
          identifiers << FHIR::Identifier.new(
            value: identifier.identifier,
            use: "secondary"
          )
        end
        patient.business_identifiers.simple_bp_passport.each do |identifier|
          identifiers << FHIR::Identifier.new(
            value: identifier.identifier,
            use: "secondary"
          )
        end
        identifiers
      end

      def gender
        return "other" unless %w[male female].include?(patient.gender)

        patient.gender
      end

      def birth_date
        return (patient.age_updated_at - patient.age.years).to_date unless patient.date_of_birth

        patient.date_of_birth.to_date
      end

      def meta
        FHIR::Meta.new(
          lastUpdated: patient.device_updated_at.iso8601,
          tag: [
            FHIR::Coding.new(
              system: "https://smartregister.org/app-version",
              code: "Not defined",
              display: "Application Version"
            ),
            FHIR::Coding.new(
              system: "https://smartregister.org/location-tag-id",
              code: opensrp_ids[:location_id],
              display: "Practitioner Location"
            ),
            FHIR::Coding.new(
              system: "https://smartregister.org/organisation-tag-id",
              code: opensrp_ids[:organization_id],
              display: "Practitioner Organization"
            ),
            FHIR::Coding.new(
              system: "https://smartregister.org/care-team-tag-id",
              code: opensrp_ids[:care_team_id],
              display: "Practitioner CareTeam"
            ),
            FHIR::Coding.new(
              system: "https://smartregister.org/care-team-tag-id",
              code: opensrp_ids[:practitioner_id],
              display: "Practitioner"
            )
          ]
        )
      end

      private

      attr_reader :opensrp_ids
    end
  end
end
