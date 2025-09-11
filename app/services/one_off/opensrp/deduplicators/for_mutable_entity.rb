module OneOff
  module Opensrp
    module Deduplicators
      class ForMutableEntity < ForEntity
        def merge
          raise "Unimplemented"
        end

        def merge_non_null(entity, old_entity, attributes)
          attributes.each do |attr|
            val = [entity, old_entity].map { |p| p.send(attr) }.compact
            if val.size > 1
              @needs_manual_merge << attr
              next
            end
            entity.send("#{attr}=", val.first)
          end
        end

        def merge_new(entity, old_patient, attributes)
          # no-op; since entity == new_entity
        end

        def merge_old(entity, old_entity, attributes)
          return if old_entity.nil?
          attributes.each do |attr|
            entity.send("#{attr}=", old_entity.send(attr))
          end
        end
      end
    end
  end
end
