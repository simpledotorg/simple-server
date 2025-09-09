module OneOff
  module Opensrp
    module Deduplicators
      class ForMedicalHistory < ForMutableEntity
        CHOOSING_NEW = %i[
          device_updated_at
          updated_at
          prior_heart_attack
          prior_stroke
          chronic_kidney_disease
          receiving_treatment_for_hypertension
          diabetes
          diagnosed_with_hypertension
          diagnosed_with_hypertension_boolean
          hypertension
          receiving_treatment_for_diabetes
          deleted_at
        ].freeze

        CHOOSING_OLD = %i[
          created_at
          device_created_at
        ].freeze

        def merge
          new_patient.medical_history.tap do |new_medical_history|
            merge_old(new_medical_history, old_patient.medical_history, CHOOSING_OLD)
            merge_new(new_medical_history, old_patient.medical_history, CHOOSING_NEW)
          end
        end
      end
    end
  end
end
