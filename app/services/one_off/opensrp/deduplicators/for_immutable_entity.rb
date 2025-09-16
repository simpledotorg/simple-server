module OneOff
  module Opensrp
    module Deduplicators
      class ForImmutableEntity < ForEntity
        def initialize old_id, new_id, assoc = nil
          super(old_id, new_id)

          @association = assoc
        end

        def merge
          old_patient.send(@association).each do |associated|
            associated.patient = new_patient
            associated.save!
          end

          # return the old patient object for the chain
          old_patient
        end
      end
    end
  end
end
