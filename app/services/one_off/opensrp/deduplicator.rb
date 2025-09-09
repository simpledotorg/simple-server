# frozen_string_literals: true

module OneOff
  module Opensrp
    class ImportedDuplicatesQuery
      def self.call
        new.call
      end

      def call
        query.map { |patient| [patient.id, patient.patient_id] }
      end

      private

      def query
        Patient
          .joins("inner join patient_business_identifiers on patient_business_identifiers.identifier = patients.id::text")
          .select("patients.id, patient_business_identifiers.patient_id")
      end
    end

    class Deduplicator
      AFFECTED_ENTITIES = %w[
        Appointment
        BloodPressure
        BloodSugar
        MedicalHistory
        PrescriptionDrug
        Patient
      ].freeze
      # The order is important here. Patient must be last.

      def self.call!
        new.call!
      end

      def initialize
        @duplicates = ImportedDuplicatesQuery.call
      end

      def call!
        @duplicates.each do |old_id, new_id|
          AFFECTED_ENTITIES.each do |entity|
            deduplicator = [
              Module.nesting[1],
              "Deduplicators",
              "For#{entity}"
            ].join("::").constantize
            deduplicator.call! old_id, new_id
          end
        end
      end
    end
  end
end
