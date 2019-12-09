module Api::Current::SyncEncounter
  extend ActiveSupport::Concern
  included do
    def add_encounter_and_merge_record(key, params)
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
          key => [params]
        }
      }.with_indifferent_access

      MergeEncounterService.new(encounter_merge_params, current_facility, current_user, current_timezone_offset).merge
    end
  end
end
