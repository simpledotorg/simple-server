module PatientDeduplication
  module Strategies
    class << self
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
      def identifier_excluding_full_name_match(limit: nil)
        matches = PatientBusinessIdentifier
          .select("identifier, array_agg(patient_id) as patient_ids")
          .joins(:patient)
          .where.not(identifier: "")
          .where(identifier_type: simple_bp_passport)
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
