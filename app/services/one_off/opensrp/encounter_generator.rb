require "fhir_models"

module OneOff
  module Opensrp
    class EncounterGenerator
      attr_reader :encounters

      def initialize(encounters)
        @encounters = encounters
      end

      def export_deduplicated
        encounters.group_by(&:id).map do |_, matching_encounters|
          matching_encounters.max_by { |encounter| encounter.meta.lastUpdated }
        end
      end
    end
  end
end
