module Api
  module V3
    module Historical
      class EncountersController < HistoricalSyncController
        before_action :stub_syncing_from_user, only: [:sync_from_user]
        before_action :stub_syncing_to_user, only: [:sync_to_user]
        def sync_from_user
          __sync_from_user__(encounters_params)
        end

        def sync_to_user
          __sync_to_user__("encounters")
        end

        private

        def merge_if_valid(single_encounter_params)
          encounter_values = single_encounter_params.except(:observations)
          record_params = Api::V3::Transformer.from_request(encounter_values)

          encounter = Encounter.find_or_initialize_by(id: record_params[:id])
          safe_assign_attributes(encounter, record_params)

          unless encounter.save(validate: false)
            return {
              errors_hash: {
                id: record_params[:id],
                error_type: "encounter_save_failed",
                message: encounter.errors.full_messages.join(", ")
              }
            }
          end

          observations = single_encounter_params[:observations] || {}

          observations.each do |observation_type, observation_list|
            Array(observation_list).each do |observation_params|
              merge_observation(encounter, observation_type, observation_params)
            end
          end

          {record: encounter}
        end

        def merge_observation(encounter, observation_type, observation_params)
          case observation_type.to_sym
          when :blood_pressures
            merge_blood_pressure(encounter, observation_params)
          end
        end

        def merge_blood_pressure(encounter, bp_params)
          record_params = Api::V3::BloodPressureTransformer.from_request(bp_params)
          blood_pressure = BloodPressure.find_or_initialize_by(id: record_params[:id])
          safe_assign_attributes(blood_pressure, record_params)

          if blood_pressure.save(validate: false)
            begin
              blood_pressure.find_or_update_observation!(encounter, current_user)
            rescue => e
              Rails.logger.info "Error linking blood pressure #{blood_pressure.id} to encounter #{encounter.id}: #{e.message}"
            end
          else
            Rails.logger.info "Failed to save historical blood pressure #{blood_pressure.id}: #{blood_pressure.errors.full_messages.join(", ")}"
          end
        end

        def transform_to_response(encounter)
          Api::V3::EncounterTransformer.to_response(encounter)
        end

        def encounters_params
          permitted_bp_params = %i[
            id
            systolic
            diastolic
            patient_id
            facility_id
            user_id
            created_at
            updated_at
            recorded_at
            deleted_at
          ]

          params.require(:encounters).map do |encounter_params|
            encounter_params.permit(
              :id,
              :patient_id,
              :facility_id,
              :encountered_on,
              :notes,
              :created_at,
              :updated_at,
              :deleted_at,
              :timezone_offset,
              observations: [
                blood_pressures: [permitted_bp_params]
              ]
            )
          end
        end

        def generate_id
          raise ActionController::RoutingError.new("Not Found") unless Flipper.enabled?("generate_encounter_id_endpoint")

          params.require([:facility_id, :patient_id, :encountered_on])

          render plain: Encounter.generate_id(params[:facility_id].strip,
            params[:patient_id].strip,
            params[:encountered_on].strip),
            status: :ok
        end

        def stub_syncing_from_user
          unless Flipper.enabled?("sync_encounters")
            render json: {processed: [], errors: []}, status: :ok
          end
        end

        def stub_syncing_to_user
          unless Flipper.enabled?("sync_encounters")
            render(
              json: {"encounters" => [], "process_token" => encode_process_token({})},
              status: :ok
            )
          end
        end
      end
    end
  end
end
