module OneOff
  module Opensrp
    module Deduplicators
      class ForEntity
        def self.call! old_id, new_id
          new(old_id, new_id).call
        end

        def initialize old_id, new_id
          @old_id = old_id
          @new_id = new_id
        end

        def new_patient
          @new_patient ||= Patient.find(@new_id)
        end

        def old_patient
          @old_patient ||= Patient.find(@old_id)
        end

        def call!
          merge.save!
        end

        def merge
          raise "Unimplemented"
        end
      end
    end
  end
end
