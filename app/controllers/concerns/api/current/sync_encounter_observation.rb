module Api::Current::SyncEncounterObservation
  extend ActiveSupport::Concern
  included do

    def merge_encounter_observation(key, params)
      ActiveRecord::Base.transaction do
        if FeatureToggle.enabled?('SYNC_ENCOUNTERS')
          # this will always return a single blood_sugar
          add_encounter_and_merge_record(key, params)[:observations][key][0]
        else
          key.to_s.classify.constantize.merge(params)
        end
      end
    end

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

    def set_patient_recorded_at(bp_params)
      # We don't set the patient recorded if retroactive data-entry is supported by the app
      # If the app supports retroactive data-entry, we expect the app to update the patients and sync
      return if bp_params['recorded_at'].present?

      patient = Patient.find_by(id: bp_params['patient_id'])
      # If the patient is not synced yet, we simply ignore setting patient's recorded_at
      return if patient.blank?

      # We only try to set the patient's recorded_at when retroactive data-entry is not supported on the app
      patient.recorded_at = patient_recorded_at(bp_params, patient)
      patient.save
    end

    #
    # Patient recorded_at is the earlier of the two:
    #   1. Patient's earliest recorded blood pressure
    #   2. Patient's device_created_at
    #   3. The device_created_at of the current blood pressure being synced
    #
    def patient_recorded_at(bp_params, patient)
      earliest_blood_pressure = patient.blood_pressures.order(recorded_at: :asc).first
      [bp_params['created_at'], earliest_blood_pressure&.recorded_at, patient.device_created_at].compact.min
    end
  end
end
