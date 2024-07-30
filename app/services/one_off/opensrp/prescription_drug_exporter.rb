require "fhir_models"

module OneOff
  module Opensrp
    class PrescriptionDrugExporter
      attr_reader :prescription_drug

      def initialize(prescription_drug, opensrp_mapping)
        @prescription_drug = prescription_drug
        @opensrp_ids = opensrp_mapping[@prescription_drug.facility_id]
      end

      def export
        FHIR::MedicationDispense.new(
          id: prescription_drug.id,
          status: prescription_drug.is_deleted ? "stopped" : "completed",
          medicationReference: FHIR::Reference.new(
            reference: "Medication/#{Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, "medication" + prescription_drug.id)}"
          ),
          context: FHIR::Reference.new(
            reference: "Encounter/#{encounter_id}"
          ),
          # type: FHIR::CodeableConcept.new(
          #   coding: [
          #     FHIR::Coding.new(
          #       system: "http://terminology.hl7.org/ValueSet/v3-ActPharmacySupplyType",
          #       code: "TODO"
          #     )
          #   ]
          # ),
          performer: [{
            actor: FHIR::Reference.new(
              reference: "Practitioner/#{opensrp_ids[:practitioner_id]}"
            )
          }],
          subject: FHIR::Reference.new(
            reference: "Patient/#{prescription_drug.patient_id}"
          ),
          whenPrepared: nil,
          whenHandedOver: prescription_drug.device_created_at.iso8601,
          meta: meta
        )
      end

      def export_medication
        FHIR::Medication.new(
          id: Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, "medication" + prescription_drug.id),
          identifier: FHIR::Identifier.new(value: Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, "medication" + prescription_drug.id)),
          status: prescription_drug.is_deleted ? "inactive" : "active",
          code: FHIR::CodeableConcept.new(
            coding: FHIR::Coding.new(
              system: "http://www.nlm.nih.gov/research/umls/rxnorm",
              code: prescription_drug.rxnorm_code,
              display: prescription_drug.name
            )
          )
        )
      end

      def export_dosage_flag
        FHIR::Flag.new(
          id: flag_id,
          meta: {
            lastUpdated: "2024-06-11T09:14:59.356+03:00",
            tag: [
              {
                system: "https://smartregister.org/care-team-tag-id",
                code: opensrp_ids[:care_team_id],
                display: "Practitioner CareTeam"
              },
              {
                system: "https://smartregister.org/location-tag-id",
                code: opensrp_ids[:location_id],
                display: "Practitioner Location"
              },
              {
                system: "https://smartregister.org/organisation-tag-id",
                code: opensrp_ids[:organization_id],
                display: "Practitioner Organization"
              },
              {
                system: "https://smartregister.org/practitioner-tag-id",
                code: opensrp_ids[:practitioner_id],
                display: "Practitioner"
              },
              {
                system: "https://smartregister.org/app-version",
                code: "2.0.0-diabetesCompassClinic",
                display: "Application Version"
              }
            ]
          },
          identifier: [
            {
              use: "usual",
              value: flag_id
            }
          ],
          status: "active",
          category: [
            {
              coding: [
                {
                  system: "http://terminology.hl7.org/CodeSystem/flag-category",
                  code: "clinical",
                  display: "Clinical"
                }
              ],
              text: "Clinical"
            }
          ],
          code: {
            coding: [
              {
                system: "https://smartregister.org/",
                code: "GENPATIENTNOTES",
                display: "General patient notes"
              }
            ],
            text: "#{prescription_drug.name} #{prescription_drug.dosage || ""} #{prescription_drug.frequency || ""}"
          },
          subject: {
            reference: "Patient/#{prescription_drug.patient_id}"
          },
          period: {
            start: prescription_drug.device_created_at.beginning_of_day.iso8601,
            end: prescription_drug.device_created_at.end_of_day.iso8601
          },
          encounter: {
            reference: "Encounter/#{encounter_id}"
          },
          author: {
            reference: "Practitioner/#{opensrp_ids[:practitioner_id]}"
          }
        )
      end

      def export_encounter
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
              code: "AMB"
            ),
            type: [
              FHIR::CodeableConcept.new(
                coding: FHIR::Coding.new(
                  system: "http://snomed.info/sct",
                  code: "44054006"
                )
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
            subject: FHIR::Reference.new(reference: "Patient/#{prescription_drug.patient_id}"),
            period: FHIR::Period.new(start: prescription_drug.updated_at.iso8601),
            reasonCode: [
              FHIR::CodeableConcept.new(
                coding: [
                  FHIR::Coding.new(
                    system: "http://snomed.info/sct",
                    code: "1156892006" # TODO
                  )
                ]
              )
            ],
            diagnosis: nil,
            location: nil,
            serviceProvider: FHIR::Reference.new(reference: "Organization/#{opensrp_ids[:organization_id]}"),
            partOf: FHIR::Reference.new(reference: "Encounter/#{parent_encounter_id}")
          )
        }
      end

      def flag_id
        Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, prescription_drug.id + "_dosage_flag_id")
      end

      def encounter_id
        Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, prescription_drug.id)
      end

      def parent_encounter_id
        "patient-visit-#{meta.lastUpdated.to_date.iso8601}-#{prescription_drug.patient_id}"
      end

      def dosage_instruction
        unless dosage_value.present?
          Rails.logger.warn("Dosage #{prescription_drug.dosage} does not match expected regex. Not exporting dosageInstruction")
          return
        end

        timing = nil
        if prescription_drug.frequency.present?
          timing = FHIR::Timing.new(
            code: FHIR::CodeableConcept.new(
              coding: FHIR::Coding.new(
                code: medication_frequency_code
              )
            )
          )
        end

        [
          FHIR::Dosage.new(
            doseAndRate: [
              FHIR::Dosage::DoseAndRate.new(
                doseQuantity: FHIR::Quantity.new(
                  value: dosage_value,
                  unit: "mg",
                  system: "http://unitsofmeasure.org"
                )
              )
            ],
            timing: timing
          )
        ]
      end

      # There are a number of ways dosage can be entered without
      # conforming to the below regex. We're only parsing values
      # in mg without frequency added in the dosage string. This
      # can be updated in the future as required.
      def dosage_value
        dosage = prescription_drug.dosage.delete(" ").downcase
        regex = /\A[0-9]*.?[0-9]*?mg\z/
        dosage.match(regex)&.to_s&.delete_suffix("mg")
      end

      def medication_frequency_code
        case prescription_drug.frequency
        when "OD" then "QD"
        when "BD" then "BID"
        when "TDS" then "TID"
        when "QDS" then "QID"
        else raise "Invalid prescription drug frequency: #{prescription_drug.frequency}"
        end
      end

      def meta
        FHIR::Meta.new(
          lastUpdated: prescription_drug.device_updated_at.iso8601,
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
