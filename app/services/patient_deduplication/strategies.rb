# frozen_string_literal: true

module PatientDeduplication
  module Strategies
    class << self
      ALLOWED_IDENTIFIER_TYPES = %w[simple_bp_passport bangladesh_national_id india_national_health_id]

      # Exact match based on identifiers, and case insensitive full names
      def identifier_and_full_name_match(limit: nil)
        duplicate_identifiers
          .group("lower(full_name)")
          .then { |matches| duplicate_patient_ids(matches, limit: limit) }
      end

      # Exact match of just identifiers, excluding exact name matches
      def identifier_excluding_full_name_match(limit: nil)
        duplicate_identifiers
          .having("COUNT(distinct lower(full_name)) > 1")
          .then { |matches| duplicate_patient_ids(matches, limit: limit) }
      end

      # Exact match of just identifiers, excluding exact name matches
      # optimised to work well for a small set of facilities, say within a district.
      def identifier_excluding_full_name_match_for_facilities(facilities:, limit: nil)
        duplicate_identifiers
          .where(identifier: identifiers_for_facilities(facilities))
          .having("COUNT(distinct lower(full_name)) > 1")
          .then { |matches| duplicate_patient_ids(matches, limit: limit) }
      end

      private

      def duplicate_patient_ids(matches, limit: nil)
        return matches.map(&:patient_ids) unless limit.present?

        matches.limit(limit).map(&:patient_ids)
      end

      def duplicate_identifiers
        PatientBusinessIdentifier
          .joins(:patient)
          .select("identifier, array_agg(patient_id) as patient_ids")
          .where.not(identifier: "")
          .where(identifier_type: ALLOWED_IDENTIFIER_TYPES)
          .group("identifier, identifier_type")
          .having("COUNT(distinct patient_id) > 1")
      end

      def identifiers_for_facilities(facilities)
        PatientBusinessIdentifier
          .joins(:patient)
          .where(patients: {assigned_facility: facilities})
          .pluck("identifier")
      end
    end
  end
end
