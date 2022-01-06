# frozen_string_literal: true

module Api::V3::SyncEncounterObservation
  extend ActiveSupport::Concern
  included do
    def merge_encounter_observation(observation_name, params)
      ActiveRecord::Base.transaction do
        add_encounter_and_merge_record(observation_name, params)
      end
    end

    def add_encounter_and_merge_record(observation_name, params)
      encountered_on = Encounter.generate_encountered_on(params[:recorded_at], current_timezone_offset)

      encounter_merge_params = {
        id: Encounter.generate_id(params[:facility_id], params[:patient_id], encountered_on),
        patient_id: params[:patient_id],
        device_created_at: params[:device_created_at],
        device_updated_at: params[:device_updated_at],
        encountered_on: encountered_on,
        timezone_offset: current_timezone_offset,
        facility_id: params[:facility_id],
        observations: {
          observation_name => [params]
        }
      }.with_indifferent_access

      MergeEncounterService.new(encounter_merge_params, current_user, current_timezone_offset)
        .merge # this will always return a single observation
        .dig(:observations, observation_name, 0)
    end
  end
end
