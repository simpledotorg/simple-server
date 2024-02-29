require "fhir_models"

module OneOff
  module Opensrp
    class PrescriptionDrugExporter
      attr_reader :prescription_drug

      def initialize(prescription_drug)
        @prescription_drug = prescription_drug
      end

      def export
        FHIR::MedicationDispense.new(
          id: prescription_drug.id,
          status: prescription_drug.is_deleted ? "stopped" : "completed",
          medicationReference: FHIR::Reference.new(
            identifier: FHIR::Identifier.new(
              value: Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, "dispense" + prescription_drug.id)
            )
          ),
          context: FHIR::Reference.new(
            identifier: FHIR::Identifier.new(
              value: Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, "encounter" + prescription_drug.id)
            )
          ),
          # type: FHIR::CodeableConcept.new(
          #   coding: [
          #     FHIR::Coding.new(
          #       system: "http://terminology.hl7.org/ValueSet/v3-ActPharmacySupplyType",
          #       code: "TODO"
          #     )
          #   ]
          # ),
          performer: FHIR::Reference.new(
            identifier: FHIR::Identifier.new(
              value: prescription_drug.facility_id
            )
          ),
          subject: FHIR::Reference.new(
            identifier: FHIR::Identifier.new(
              value: prescription_drug.patient_id
            )
          ),
          whenPrepared: nil,
          whenHandedOver: prescription_drug.device_created_at.iso8601,
          meta: FHIR::Meta.new(
            lastUpdated: prescription_drug.device_updated_at.iso8601,
            createdAt: prescription_drug.device_created_at.iso8601
          )
        )
      end

      def export_medication
        FHIR::Medication.new(
          id: prescription_drug.id,
          identifier: FHIR::Identifier.new(value: prescription_drug.id),
          code: FHIR::CodeableConcept.new(
            coding: FHIR::Coding.new(
              system: "http://www.nlm.nih.gov/research/umls/rxnorm",
              code: prescription_drug.rxnorm_code,
              display: prescription_drug.name
            )
          )
        )
      end

      def export_encounter
        FHIR::Encounter.new(
          meta: meta,
          status: "finished",
          id: Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, "encounter" + prescription_drug.id),
          identifier: [
            FHIR::Identifier.new(
              value: Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, "encounter" + prescription_drug.id)
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
          period: FHIR::Period.new(start: prescription_drug.updated_at.iso8601), # TODO: we don't store end period
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
          serviceProvider: FHIR::Reference.new(reference: "Organization/#{prescription_drug.facility_id}"),
          partOf: nil
        )
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

      def dispense_request
        return if prescription_drug.duration_in_days.nil?

        FHIR::MedicationRequest::DispenseRequest.new(
          expectedSupplyDuration: FHIR::Duration.new(
            value: prescription_drug.duration_in_days,
            unit: "days",
            system: "http://unitsofmeasure.org",
            code: "d"
          )
        )
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
              code: "TODO", # TODO
              display: "Practitioner Location"
            ),
            FHIR::Coding.new(
              system: "https://smartregister.org/organisation-tag-id",
              code: "TODO", # TODO
              display: "Practitioner Organization"
            ),
            FHIR::Coding.new(
              system: "https://smartregister.org/care-team-tag-id",
              code: "TODO", # TODO
              display: "Practitioner CareTeam"
            )
          ]
        )
      end
    end
  end
end
