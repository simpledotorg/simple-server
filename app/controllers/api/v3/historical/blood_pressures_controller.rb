module Api
  module V3
    module Historical
      class BloodPressuresController < HistoricalSyncController
        include Api::V3::RetroactiveDataEntry

        def sync_from_user
          __sync_from_user__(blood_pressures_params)
        end

        def sync_to_user
          __sync_to_user__("blood_pressures")
        end

        private

        def merge_if_valid(bp_params)
          set_patient_recorded_at(bp_params)

          transformed_params = Api::V3::BloodPressureTransformer.from_request(bp_params)

          blood_pressure = BloodPressure.find_or_initialize_by(id: transformed_params[:id])
          safe_assign_attributes(blood_pressure, transformed_params)

          if blood_pressure.save(validate: false)
            {record: blood_pressure}
          else
            {
              errors_hash: {
                id: transformed_params[:id],
                error_type: "save_failed",
                message: blood_pressure.errors.full_messages.join(", ")
              }
            }
          end
        end

        def transform_to_response(blood_pressure)
          Api::V3::Transformer.to_response(blood_pressure)
        end

        def blood_pressures_params
          params.require(:blood_pressures).map do |blood_pressure_params|
            blood_pressure_params.permit(
              :id,
              :systolic,
              :diastolic,
              :patient_id,
              :facility_id,
              :user_id,
              :created_at,
              :updated_at,
              :recorded_at,
              :deleted_at
            )
          end
        end
      end
    end
  end
end
