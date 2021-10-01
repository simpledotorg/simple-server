class RemoveUnusedIndexes < ActiveRecord::Migration[5.2]
  def change
    remove_index :twilio_sms_delivery_details, name: "index_twilio_sms_delivery_details_on_deleted_at"
    remove_index :patients, name: "index_patients_on_reminder_consent"
    remove_index :appointments, name: "index_appointments_on_deleted_at"
    remove_index :appointments, name: "index_appointments_on_appointment_type"
    remove_index :prescription_drugs, name: "index_prescription_drugs_on_teleconsultation_id"
    remove_index :medical_histories, name: "index_medical_histories_on_user_id"
    remove_index :medical_histories, name: "index_medical_histories_on_deleted_at"
    remove_index :exotel_phone_number_details, name: "index_exotel_phone_number_details_on_whitelist_status"
    remove_index :exotel_phone_number_details, name: "index_exotel_phone_number_details_on_patient_phone_number_id"
    remove_index :exotel_phone_number_details, name: "index_exotel_phone_number_details_on_deleted_at"
    remove_index :blood_sugars, name: "index_blood_sugars_on_blood_sugar_value"
    remove_index :facilities, name: "index_gin_facilities_on_slug"
    remove_index :facilities, name: "index_gin_facilities_on_name"
    remove_index :call_logs, name: "index_call_logs_on_deleted_at"
    remove_index :drug_stocks, name: "index_drug_stocks_on_user_id"
    remove_index :drug_stocks, name: "index_drug_stocks_on_protocol_drug_id"
    remove_index :latest_blood_pressures_per_patient_per_months, name: "index_bp_months_medical_history_hypertension"
    remove_index :latest_blood_pressures_per_patient_per_months, name: "index_bp_months_registration_facility_id"
    remove_index :latest_blood_pressures_per_patients, name: "index_latest_bp_per_patient_patient_id"
  end
end
