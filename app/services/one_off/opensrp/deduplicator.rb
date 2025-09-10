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

      def self.call! duplicates = nil
        new(duplicates).call!
      end

      def initialize duplicates
        @duplicates = if duplicates.nil?
          ImportedDuplicatesQuery.call
        else
          duplicates
        end
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

        deprecate_old_patients
      end

      def deprecate_old_patients
        @old_patients = @duplicates.map(&:first)
        Patient.where(id: @old_patients).discard!
      end
    end
  end
end
