module OneOff
  module Opensrp
    module Deduplicators
      class ForImmutableEntity < ForEntity
        def initialize old_id, new_id, assoc = nil
          super(old_id, new_id)

          @association = assoc
        end

        def merge
          if is_has_many?(@association)
            old_patient.send(@association).each do |associated|
              new_patient.send(@association) << associated.dup
            end
          else
            old_patient.send(@association).each do |associated|
              duplicate = associated.dup
              duplicate.patient = new_patient
              duplicate.save!
            end
          end

          # return the old patient object for the chain
          old_patient
        end

        private

        def is_has_many? assoc
          Patient
            .reflect_on_all_associations(:has_many)
            .map(&:name)
            .include?(assoc)
        end
      end
    end
  end
end
