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
      # The order is important here. Patient must be last.
      MUTABLE_ENTITIES = %w[
        MedicalHistory
        Patient
      ].freeze

      # These are the immutable associations to the patient record, for which
      # our merge strategy is to point the old record to the new patient.
      # i.e. take the old record and set the patient_id to the new record
      IMMUTABLE_PATIENT_ASSOCIATIONS = %i[
        appointments
        blood_pressures
        blood_sugars
        call_results
        encounters
        notifications
        phone_numbers
        prescription_drugs
        teleconsultations
        treatment_group_memberships
      ]

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
          IMMUTABLE_PATIENT_ASSOCIATIONS.each do |association|
            entity = "ImmutableEntity"
            deduplicator = deduplicator_class(entity)
            deduplicator.call! old_id, new_id, association
          end

          MUTABLE_ENTITIES.each do |entity|
            deduplicator = deduplicator_class(entity)
            deduplicator.call! old_id, new_id
          end
        end

        deprecate_old_patients
      end

      def deprecate_old_patients
        @old_patients = @duplicates.map(&:first)
        Patient.where(id: @old_patients).map(&:discard!)
      end

      private

      def deduplicator_class entity
        [
          Module.nesting[1],
          "Deduplicators",
          "For#{entity}"
        ].join("::").constantize
      end
    end
  end
end
