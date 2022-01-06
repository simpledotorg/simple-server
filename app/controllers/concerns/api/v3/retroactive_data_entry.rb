# frozen_string_literal: true

module Api::V3::RetroactiveDataEntry
  extend ActiveSupport::Concern
  included do
    def set_patient_recorded_at(params)
      # We don't set the patient recorded if retroactive data-entry is supported by the app
      # If the app supports retroactive data-entry, we expect the app to update the patients and sync
      return if params["recorded_at"].present?

      patient = Patient.find_by(id: params["patient_id"])
      # If the patient is not synced yet, we simply ignore setting patient's recorded_at
      return if patient.blank?

      # We only try to set the patient's recorded_at when retroactive data-entry is not supported on the app
      patient.recorded_at = patient_recorded_at(params, patient)
      patient.save
    end

    #
    # Patient recorded_at is the earlier of the two:
    #   1. Patient's earliest recorded blood pressure
    #   2. Patient's device_created_at
    #   3. The device_created_at of the v3 blood pressure being synced
    #
    def patient_recorded_at(params, patient)
      earliest_blood_pressure = patient.blood_pressures.order(recorded_at: :asc).first
      [params["created_at"], earliest_blood_pressure&.recorded_at, patient.device_created_at].compact.min
    end
  end
end
