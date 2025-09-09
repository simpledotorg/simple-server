module OneOff
  module Opensrp
    module Deduplicators
      class ForMutableEntity < ForEntity
        def merge
          raise "Unimplemented"
        end

        def merge_non_null(patient, attributes)
          attributes.each do |attr|
            val = [patient, old_patient].map { |p| p.send(attr) }.compact
            if val.size > 1
              @needs_manual_merge << attr
              next
            end
            patient.send("#{attr}=", val.first)
          end
        end

        def merge_new(patient)
          # no-op; since patient == new_patient
        end

        def merge_old(patient, attributes)
          attributes.each do |attr|
            patient.send("#{attr}=", old_patient.send(attr))
          end
        end
      end
    end
  end
end
