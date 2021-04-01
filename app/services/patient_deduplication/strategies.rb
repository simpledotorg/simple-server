module PatientDeduplication
  module Strategies
    class << self
      delegate :sanitize_sql, to: ActiveRecord::Base

      # Exact match based on identifiers, and case insensitive full names
      def identifier_and_full_name_match
        PatientBusinessIdentifier
          .select("identifier, array_agg(patient_id) as patient_ids")
          .joins(:patient)
          .where.not(identifier: "")
          .where(identifier_type: simple_bp_passport)
          .group("identifier, lower(full_name)")
          .having("COUNT(distinct patient_id) > 1")
          .map(&:patient_ids)
      end

      # Exact match of just identifiers, excluding exact name matches
      # where at least one duplicate patient belongs to given facilities.
      def identifier_excluding_full_name_match(limit: nil, facilities: Facility.all)
        identifiers_for_facilities = PatientBusinessIdentifier
          .joins(:patient)
          .where(patients: {assigned_facility: facilities})
          .where.not(identifier: "")
          .where(identifier_type: simple_bp_passport)
          .pluck("identifier")

        matches = PatientBusinessIdentifier
          .select("identifier, array_agg(patient_id) as patient_ids")
          .joins(:patient)
          .where(identifier: identifiers_for_facilities)
          .group("identifier")
          .having("COUNT(distinct patient_id) > 1")
          .having("COUNT(distinct lower(full_name)) > 1")

        matches = matches.limit(limit) if limit.present?
        matches.map(&:patient_ids)
      end

      private

      def simple_bp_passport
        PatientBusinessIdentifier.identifier_types[:simple_bp_passport]
      end
    end
  end
end
