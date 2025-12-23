module Api
  module V3
    module Historical
      class EncountersController < HistoricalSyncController
        include Api::V3::SyncEncounterObservation

        def sync_from_user
          __sync_from_user__(encounter_params)
        end

        def sync_to_user
          __sync_to_user__("encounters")
        end

        private

        def merge_if_valid(single_encounter_params)
          encounter_values = single_encounter_params.except(:observations)

          transformed_encounter = Api::V3::Transformer.from_request(encounter_values)
          encounter = Encounter.find_or_initialize_by(id: transformed_encounter[:id])
          encounter.assign_attributes(transformed_encounter)

          unless encounter.save(validate: false)
            return {
              errors_hash: {
                id: transformed_encounter[:id],
                error_type: "encounter_save_failed",
                message: encounter.errors.full_messages.join(", ")
              }
            }
          end

          observations = single_encounter_params[:observations] || {}
          observations.each do |observation_type, observation_list|
            observation_list.each do |observation_params|
              merge_observation(observation_type, observation_params)
            end
          end

          {record: encounter}
        end

        def merge_observation(observation_type, params)
          case observation_type.to_sym
          when :blood_pressures
            merge_blood_pressure(params)
          end
        end

        def merge_blood_pressure(bp_params)
          transformed_params = Api::V3::BloodPressureTransformer.from_request(bp_params)
          blood_pressure = BloodPressure.find_or_initialize_by(id: transformed_params[:id])
          blood_pressure.assign_attributes(transformed_params)
          blood_pressure.save(validate: false)
        end

        def transform_to_response(encounter)
          Api::V3::Transformer.to_response(encounter)
        end

        def encounter_params
          params.require(:encounters).map do |encounter_params|
            encounter_params.permit(
              :id,
              :patient_id,
              :encountered_on,
              :notes,
              :created_at,
              :updated_at,
              :deleted_at,
              observations: [
                blood_pressures: [
                  :id,
                  :systolic,
                  :diastolic,
                  :patient_id,
                  :facility_id,
                  :user_id,
                  :recorded_at,
                  :created_at,
                  :updated_at,
                  :deleted_at
                ]
              ]
            )
          end
        end
      end
    end
  end
end
