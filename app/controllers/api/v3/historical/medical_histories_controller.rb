module Api
  module V3
    module Historical
      class MedicalHistoriesController < HistoricalSyncController
        def sync_from_user
          __sync_from_user__(medical_histories_params)
        end

        def sync_to_user
          __sync_to_user__("medical_histories")
        end

        def metadata
          {user_id: current_user.id}
        end

        private

        def merge_if_valid(medical_history_params)
          record_params = Api::V3::MedicalHistoryTransformer
            .from_request(medical_history_params)
            .merge(metadata)

          medical_history = MedicalHistory.find_or_initialize_by(id: record_params[:id])
          safe_assign_attributes(medical_history, record_params)

          if medical_history.save(validate: false)
            {record: medical_history}
          else
            {
              errors_hash: {
                id: record_params[:id],
                error_type: "save_failed",
                message: medical_history.errors.full_messages.join(", ")
              }
            }
          end
        end

        def transform_to_response(medical_history)
          Api::V3::MedicalHistoryTransformer.to_response(medical_history)
        end

        def medical_histories_params
          params.require(:medical_histories).map do |medical_history_params|
            medical_history_params.permit(
              :id,
              :patient_id,
              :prior_heart_attack,
              :prior_stroke,
              :chronic_kidney_disease,
              :receiving_treatment_for_hypertension,
              :receiving_treatment_for_diabetes,
              :diabetes,
              :hypertension,
              :diagnosed_with_hypertension,
              :smoking,
              :smokeless_tobacco,
              :cholesterol,
              :created_at,
              :updated_at
            )
          end
        end
      end
    end
  end
end
