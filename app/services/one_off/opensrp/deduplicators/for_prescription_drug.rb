module OneOff
  module Opensrp
    module Deduplicators
      class ForPrescriptionDrug < ForImmutableEntity
        def initialize old_id, new_id
          super old_id, new_id, :prescription_drugs
        end
      end
    end
  end
end
