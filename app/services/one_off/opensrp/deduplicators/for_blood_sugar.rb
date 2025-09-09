module OneOff
  module Opensrp
    module Deduplicators
      class ForBloodSugar < ForImmutableEntity
        def initialize old_id, new_id
          super old_id, new_id, :blood_sugars
        end
      end
    end
  end
end
