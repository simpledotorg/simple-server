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
              id: prescription_drug.id,
              code: FHIR::Coding.new(
                system: "http://www.nlm.nih.gov/research/umls/rxnorm",
                code: prescription_drug.rxnorm_code,
                display: prescription_drug.name
              )
            )
          ],
          dosageInstruction: [
            FHIR::Dosage.new(
              dosageAndRate: FHIR::Dosage::DoseAndRate.new(
                doseQuantity: dose_quantity
              ),
              timing: prescription_drug.frequency
            )
          ],
          dispenseRequest: FHIR::MedicationRequest::DispenseRequest.new(
            expectedSupplyDuration: FHIR::Duration.new(
              value: prescription_drug.duration_in_days
            )
          ),
          performer: FHIR::Reference.new(
            reference: FHIR::Organization.new(
              identifier: FHIR::Identifier.new(
                value: prescription_drug.facility_id
              )
            )
          ),
          subject: FHIR::Reference.new(
            reference: FHIR::Patient.new(
              identifier: FHIR::Identifier.new(
                value: prescription_drug.patient_id
              )
            )
          ),
          meta: FHIR::Meta.new(
            lastUpdated: prescription_drug.device_updated_at,
            createdAt: prescription_drug.device_created_at
          )
        )
      end

      def dose_quantity
        dosage = prescription_drug.dosage
        unit = "MG"
        value = dosage.split(unit).first
        FHIR::Quantity.new(
          value: value,
          unit: unit,
          system: "http://unitsofmeasure.org"
        )
      end
    end
  end
end
