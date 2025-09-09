module OneOff
  module Opensrp
    module Deduplicators
      class ForBloodPressure < ForImmutableEntity
        def initialize old_id, new_id
          super old_id, new_id, :blood_pressures
        end
      end
    end
  end
end
