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
              text: patient.full_name,
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
            use: "secondary"
          )
        ]
        patient.business_identifiers.simple_bp_passport.each do |identifier|
          identifiers.prepend(FHIR::Identifier.new(
            value: identifier.identifier,
            use: "secondary"
          ))
        end
        patient.business_identifiers.sri_lanka_personal_health_number.each do |identifier|
          identifiers.prepend(FHIR::Identifier.new(
            value: identifier.identifier,
            use: "official"
          ))
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

      def export_registration_encounter
        {
          parent_id: parent_encounter_id,
          encounter_opensrp_ids: opensrp_ids,
          child_encounter: FHIR::Encounter.new(
            meta: meta,
            status: "finished",
            id: encounter_id,
            identifier: [
              FHIR::Identifier.new(
                value: encounter_id
              )
            ],
            class: FHIR::Coding.new(
              system: "http://terminology.hl7.org/CodeSystem/v3-ActCode",
              code: "HH"
            ),
            type: [
              FHIR::CodeableConcept.new(
                coding: FHIR::Coding.new(
                  system: "http://snomed.info/sct",
                  code: "184047000",
                  display: "Patient registration"
                ),
                text: "Patient registration"
              )
            ],
            priority: [
              FHIR::CodeableConcept.new(
                coding: FHIR::Coding.new(
                  system: "http://snomed.info/sct",
                  code: "17621005",
                  display: "Normal"
                ),
                text: "Normal"
              )
            ],
            serviceType: FHIR::CodeableConcept.new(
              coding: [
                FHIR::Coding.new(
                  system: "http://terminology.hl7.org/CodeSystem/service-type",
                  code: "335"
                )
              ]
            ),
            subject: FHIR::Reference.new(reference: "Patient/#{patient.id}"),
            participant: {individual: FHIR::Reference.new(reference: "Practitioner/#{opensrp_ids[:practitioner_id]}")},
            period: FHIR::Period.new(start: patient.device_created_at.iso8601, end: patient.device_created_at.iso8601),
            reasonCode: [
              FHIR::CodeableConcept.new(
                coding: [
                  FHIR::Coding.new(
                    system: "http://smartregister.org/",
                    code: "client_registration",
                    display: "Client Registration"
                  )
                ],
                text: "Client Registration"
              )
            ],
            location: [
              {
                location: FHIR::Reference.new(
                  reference: "Location/#{opensrp_ids[:location_id]}",
                  display: opensrp_ids[:name]
                ),
                status: "completed",
                period: FHIR::Period.new(
                  start: patient.device_created_at.iso8601,
                  end: patient.device_created_at.iso8601
                )
              }
            ],
            serviceProvider: FHIR::Reference.new(reference: "Organization/#{opensrp_ids[:organization_id]}")
          )
        }
      end

      def encounter_id
        Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, patient.id)
      end

      def parent_encounter_id
        Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, patient.id + meta.lastUpdated.to_date.iso8601)
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
