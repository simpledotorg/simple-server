module OneOff
  module Opensrp
    module Deduplicators
      class ForAppointment < ForImmutableEntity
        def initialize old_id, new_id
          super old_id, new_id, :appointments
        end
      end
    end
  end
end
