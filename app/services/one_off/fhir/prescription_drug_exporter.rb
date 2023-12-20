require "fhir_models"

module OneOff
  module Fhir
    class PrescriptionDrugExporter
      attr_reader :prescription_drug

      def initialize(prescription_drug)
        @prescription_drug = prescription_drug
      end

      def export
        FHIR::MedicationRequest.new(
          contained: [
            FHIR::Medication.new(
              identifier: FHIR::Identifier.new(
                value: prescription_drug.id
              ),
              code: FHIR::CodeableConcept.new(
                coding: FHIR::Coding.new(
                  system: "http://www.nlm.nih.gov/research/umls/rxnorm",
                  code: prescription_drug.rxnorm_code,
                  display: prescription_drug.name
                )
              )
            )
          ],
          status: prescription_drug.is_deleted ? "ended" : "active",
          intent: "proposal",
          medicationReference: FHIR::Reference.new(
            identifier: FHIR::Identifier.new(
              value: prescription_drug.id
            )
          ),
          dosageInstruction: dosage_instruction,
          dispenseRequest: dispense_request,
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
          meta: FHIR::Meta.new(
            lastUpdated: prescription_drug.device_updated_at.iso8601,
            createdAt: prescription_drug.device_created_at.iso8601
          )
        )
      end

      def dosage_instruction
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
                  value: prescription_drug.dosage.delete_suffix("MG"),
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

      def medication_frequency_code
        case prescription_drug.frequency
        when "OD" then "QD"
        when "BD" then "BID"
        when "TDS" then "TID"
        when "QDS" then "QID"
        else raise "Invalid prescription drug frequency: #{prescription_drug.frequency}"
        end
      end
    end
  end
end
