# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_07_28_074416) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "accesses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "role", null: false
    t.string "resource_type"
    t.uuid "resource_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["resource_type", "resource_id"], name: "index_accesses_on_resource_type_and_resource_id"
    t.index ["role"], name: "index_accesses_on_role"
    t.index ["user_id", "resource_id", "resource_type"], name: "index_accesses_on_user_id_and_resource_id_and_resource_type", unique: true
    t.index ["user_id"], name: "index_accesses_on_user_id"
  end

  create_table "addresses", id: :uuid, default: nil, force: :cascade do |t|
    t.string "street_address"
    t.string "village_or_colony"
    t.string "district"
    t.string "state"
    t.string "country"
    t.string "pin"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "device_created_at", null: false
    t.datetime "device_updated_at", null: false
    t.datetime "deleted_at"
    t.string "zone"
    t.index ["deleted_at"], name: "index_addresses_on_deleted_at"
    t.index ["zone"], name: "index_addresses_on_zone"
  end

  create_table "appointments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "patient_id", null: false
    t.uuid "facility_id", null: false
    t.date "scheduled_date", null: false
    t.string "status"
    t.string "cancel_reason"
    t.datetime "device_created_at", null: false
    t.datetime "device_updated_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "remind_on"
    t.boolean "agreed_to_visit"
    t.datetime "deleted_at"
    t.string "appointment_type", null: false
    t.uuid "user_id"
    t.uuid "creation_facility_id"
    t.index ["appointment_type"], name: "index_appointments_on_appointment_type"
    t.index ["deleted_at"], name: "index_appointments_on_deleted_at"
    t.index ["facility_id"], name: "index_appointments_on_facility_id"
    t.index ["patient_id", "scheduled_date"], name: "index_appointments_on_patient_id_and_scheduled_date", order: { scheduled_date: :desc }
    t.index ["patient_id"], name: "index_appointments_on_patient_id"
    t.index ["updated_at"], name: "index_appointments_on_updated_at"
    t.index ["user_id"], name: "index_appointments_on_user_id"
  end

  create_table "blood_pressures", id: :uuid, default: nil, force: :cascade do |t|
    t.integer "systolic", null: false
    t.integer "diastolic", null: false
    t.uuid "patient_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "device_created_at", null: false
    t.datetime "device_updated_at", null: false
    t.uuid "facility_id", null: false
    t.uuid "user_id"
    t.datetime "deleted_at"
    t.datetime "recorded_at"
    t.index ["deleted_at"], name: "index_blood_pressures_on_deleted_at"
    t.index ["patient_id", "recorded_at"], name: "index_blood_pressures_on_patient_id_and_recorded_at", order: { recorded_at: :desc }
    t.index ["patient_id"], name: "index_blood_pressures_on_patient_id"
    t.index ["recorded_at"], name: "index_blood_pressures_on_recorded_at"
    t.index ["updated_at"], name: "index_blood_pressures_on_updated_at"
    t.index ["user_id"], name: "index_blood_pressures_on_user_id"
  end

  create_table "blood_sugars", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "blood_sugar_type", null: false
    t.decimal "blood_sugar_value", null: false
    t.uuid "patient_id", null: false
    t.uuid "user_id", null: false
    t.uuid "facility_id", null: false
    t.datetime "device_created_at", null: false
    t.datetime "device_updated_at", null: false
    t.datetime "deleted_at"
    t.datetime "recorded_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["blood_sugar_type"], name: "index_blood_sugars_on_blood_sugar_type"
    t.index ["blood_sugar_value"], name: "index_blood_sugars_on_blood_sugar_value"
    t.index ["facility_id"], name: "index_blood_sugars_on_facility_id"
    t.index ["patient_id"], name: "index_blood_sugars_on_patient_id"
    t.index ["updated_at"], name: "index_blood_sugars_on_updated_at"
    t.index ["user_id"], name: "index_blood_sugars_on_user_id"
  end

  create_table "call_logs", force: :cascade do |t|
    t.string "session_id"
    t.string "result"
    t.integer "duration"
    t.string "callee_phone_number", null: false
    t.datetime "start_time"
    t.datetime "end_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "caller_phone_number", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_call_logs_on_deleted_at"
  end

  create_table "communications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "appointment_id", null: false
    t.uuid "user_id"
    t.string "communication_type"
    t.datetime "device_created_at", null: false
    t.datetime "device_updated_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.string "detailable_type"
    t.bigint "detailable_id"
    t.index ["appointment_id"], name: "index_communications_on_appointment_id"
    t.index ["deleted_at"], name: "index_communications_on_deleted_at"
    t.index ["detailable_type", "detailable_id"], name: "index_communications_on_detailable_type_and_detailable_id"
    t.index ["user_id"], name: "index_communications_on_user_id"
  end

  create_table "data_migrations", id: false, force: :cascade do |t|
    t.string "version", null: false
    t.index ["version"], name: "unique_data_migrations", unique: true
  end

  create_table "email_authentications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.string "invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer "invitation_limit"
    t.uuid "invited_by_id"
    t.string "invited_by_type"
    t.integer "invitations_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index "to_tsvector('simple'::regconfig, COALESCE((email)::text, ''::text))", name: "index_gin_email_authentications_on_email", using: :gin
    t.index ["deleted_at"], name: "index_email_authentications_on_deleted_at"
    t.index ["email"], name: "index_email_authentications_on_email", unique: true
    t.index ["invitation_token"], name: "index_email_authentications_on_invitation_token", unique: true
    t.index ["invitations_count"], name: "index_email_authentications_on_invitations_count"
    t.index ["invited_by_id"], name: "index_email_authentications_on_invited_by_id"
    t.index ["invited_by_type", "invited_by_id"], name: "index_email_authentications_invited_by"
    t.index ["reset_password_token"], name: "index_email_authentications_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_email_authentications_on_unlock_token", unique: true
  end

  create_table "encounters", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "facility_id", null: false
    t.uuid "patient_id", null: false
    t.date "encountered_on", null: false
    t.integer "timezone_offset", null: false
    t.text "notes"
    t.jsonb "metadata"
    t.datetime "device_created_at", null: false
    t.datetime "device_updated_at", null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_encounters_on_deleted_at"
    t.index ["facility_id"], name: "index_encounters_on_facility_id"
    t.index ["patient_id"], name: "index_encounters_on_patient_id"
  end

  create_table "exotel_phone_number_details", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "patient_phone_number_id", null: false
    t.string "whitelist_status"
    t.datetime "whitelist_requested_at"
    t.datetime "whitelist_status_valid_until"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_exotel_phone_number_details_on_deleted_at"
    t.index ["patient_phone_number_id"], name: "index_exotel_phone_number_details_on_patient_phone_number_id"
    t.index ["patient_phone_number_id"], name: "index_unique_exotel_phone_number_details_on_phone_number_id", unique: true
    t.index ["whitelist_status"], name: "index_exotel_phone_number_details_on_whitelist_status"
  end

  create_table "facilities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "street_address"
    t.string "village_or_colony"
    t.string "district"
    t.string "state"
    t.string "country"
    t.string "pin"
    t.string "facility_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "latitude"
    t.float "longitude"
    t.datetime "deleted_at"
    t.uuid "facility_group_id"
    t.string "slug"
    t.string "zone"
    t.boolean "enable_diabetes_management", default: false, null: false
    t.string "facility_size"
    t.integer "monthly_estimated_opd_load"
    t.boolean "enable_teleconsultation", default: false, null: false
    t.string "teleconsultation_phone_number"
    t.string "teleconsultation_isd_code"
    t.jsonb "teleconsultation_phone_numbers", default: [], null: false
    t.index "to_tsvector('simple'::regconfig, COALESCE((name)::text, ''::text))", name: "index_gin_facilities_on_name", using: :gin
    t.index "to_tsvector('simple'::regconfig, COALESCE((slug)::text, ''::text))", name: "index_gin_facilities_on_slug", using: :gin
    t.index ["deleted_at"], name: "index_facilities_on_deleted_at"
    t.index ["enable_diabetes_management"], name: "index_facilities_on_enable_diabetes_management"
    t.index ["facility_group_id"], name: "index_facilities_on_facility_group_id"
    t.index ["slug"], name: "index_facilities_on_slug", unique: true
  end

  create_table "facility_groups", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.uuid "organization_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.uuid "protocol_id"
    t.string "slug"
    t.index ["deleted_at"], name: "index_facility_groups_on_deleted_at"
    t.index ["organization_id"], name: "index_facility_groups_on_organization_id"
    t.index ["protocol_id"], name: "index_facility_groups_on_protocol_id"
    t.index ["slug"], name: "index_facility_groups_on_slug", unique: true
  end

  create_table "flipper_features", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_flipper_features_on_key", unique: true
  end

  create_table "flipper_gates", force: :cascade do |t|
    t.string "feature_key", null: false
    t.string "key", null: false
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["feature_key", "key", "value"], name: "index_flipper_gates_on_feature_key_and_key_and_value", unique: true
  end

  create_table "medical_histories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "patient_id", null: false
    t.boolean "prior_heart_attack_boolean"
    t.boolean "prior_stroke_boolean"
    t.boolean "chronic_kidney_disease_boolean"
    t.boolean "receiving_treatment_for_hypertension_boolean"
    t.boolean "diabetes_boolean"
    t.datetime "device_created_at", null: false
    t.datetime "device_updated_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "diagnosed_with_hypertension_boolean"
    t.text "prior_heart_attack"
    t.text "prior_stroke"
    t.text "chronic_kidney_disease"
    t.text "receiving_treatment_for_hypertension"
    t.text "diabetes"
    t.text "diagnosed_with_hypertension"
    t.datetime "deleted_at"
    t.uuid "user_id"
    t.text "hypertension"
    t.index ["deleted_at"], name: "index_medical_histories_on_deleted_at"
    t.index ["patient_id"], name: "index_medical_histories_on_patient_id"
    t.index ["user_id"], name: "index_medical_histories_on_user_id"
  end

  create_table "observations", force: :cascade do |t|
    t.uuid "encounter_id", null: false
    t.uuid "user_id", null: false
    t.string "observable_type"
    t.uuid "observable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_observations_on_deleted_at"
    t.index ["encounter_id"], name: "index_observations_on_encounter_id"
    t.index ["observable_type", "observable_id"], name: "idx_observations_on_observable_type_and_id", unique: true
    t.index ["user_id"], name: "index_observations_on_user_id"
  end

  create_table "organizations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.string "slug"
    t.index ["deleted_at"], name: "index_organizations_on_deleted_at"
    t.index ["slug"], name: "index_organizations_on_slug", unique: true
  end

  create_table "passport_authentications", force: :cascade do |t|
    t.string "access_token", null: false
    t.string "otp", null: false
    t.datetime "otp_expires_at", null: false
    t.uuid "patient_business_identifier_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "patient_business_identifiers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "identifier", null: false
    t.string "identifier_type", null: false
    t.uuid "patient_id", null: false
    t.string "metadata_version"
    t.json "metadata"
    t.datetime "device_created_at", null: false
    t.datetime "device_updated_at", null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_patient_business_identifiers_on_deleted_at"
    t.index ["patient_id"], name: "index_patient_business_identifiers_on_patient_id"
  end

  create_table "patient_phone_numbers", id: :uuid, default: nil, force: :cascade do |t|
    t.string "number"
    t.string "phone_type"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "patient_id"
    t.datetime "device_created_at", null: false
    t.datetime "device_updated_at", null: false
    t.datetime "deleted_at"
    t.boolean "dnd_status", default: true, null: false
    t.index ["deleted_at"], name: "index_patient_phone_numbers_on_deleted_at"
    t.index ["dnd_status"], name: "index_patient_phone_numbers_on_dnd_status"
    t.index ["patient_id"], name: "index_patient_phone_numbers_on_patient_id"
  end

  create_table "patients", id: :uuid, default: nil, force: :cascade do |t|
    t.string "full_name"
    t.integer "age"
    t.string "gender"
    t.date "date_of_birth"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "address_id"
    t.datetime "age_updated_at"
    t.datetime "device_created_at", null: false
    t.datetime "device_updated_at", null: false
    t.boolean "test_data", default: false, null: false
    t.uuid "registration_facility_id"
    t.uuid "registration_user_id"
    t.datetime "deleted_at"
    t.boolean "contacted_by_counsellor", default: false
    t.string "could_not_contact_reason"
    t.datetime "recorded_at"
    t.string "reminder_consent", default: "denied", null: false
    t.uuid "deleted_by_user_id"
    t.string "deleted_reason"
    t.uuid "assigned_facility_id"
    t.index ["assigned_facility_id"], name: "index_patients_on_assigned_facility_id"
    t.index ["deleted_at"], name: "index_patients_on_deleted_at"
    t.index ["recorded_at"], name: "index_patients_on_recorded_at"
    t.index ["registration_facility_id"], name: "index_patients_on_registration_facility_id"
    t.index ["registration_user_id"], name: "index_patients_on_registration_user_id"
    t.index ["reminder_consent"], name: "index_patients_on_reminder_consent"
    t.index ["updated_at"], name: "index_patients_on_updated_at"
  end

  create_table "phone_number_authentications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "phone_number", null: false
    t.string "password_digest", null: false
    t.string "otp", null: false
    t.datetime "otp_expires_at", null: false
    t.datetime "logged_in_at"
    t.string "access_token", null: false
    t.uuid "registration_facility_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "locked_at"
    t.index "to_tsvector('simple'::regconfig, COALESCE((phone_number)::text, ''::text))", name: "index_gin_phone_number_authentications_on_phone_number", using: :gin
    t.index ["deleted_at"], name: "index_phone_number_authentications_on_deleted_at"
  end

  create_table "prescription_drugs", id: :uuid, default: nil, force: :cascade do |t|
    t.string "name", null: false
    t.string "rxnorm_code"
    t.string "dosage"
    t.datetime "device_created_at", null: false
    t.datetime "device_updated_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "patient_id", null: false
    t.uuid "facility_id", null: false
    t.boolean "is_protocol_drug", null: false
    t.boolean "is_deleted", null: false
    t.datetime "deleted_at"
    t.uuid "user_id"
    t.index ["deleted_at"], name: "index_prescription_drugs_on_deleted_at"
    t.index ["patient_id"], name: "index_prescription_drugs_on_patient_id"
    t.index ["user_id"], name: "index_prescription_drugs_on_user_id"
  end

  create_table "protocol_drugs", id: :uuid, default: nil, force: :cascade do |t|
    t.string "name", null: false
    t.string "dosage", null: false
    t.string "rxnorm_code"
    t.uuid "protocol_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_protocol_drugs_on_deleted_at"
  end

  create_table "protocols", id: :uuid, default: nil, force: :cascade do |t|
    t.string "name", null: false
    t.integer "follow_up_days"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_protocols_on_deleted_at"
  end

  create_table "twilio_sms_delivery_details", force: :cascade do |t|
    t.string "session_id"
    t.string "result"
    t.string "callee_phone_number", null: false
    t.datetime "delivered_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_twilio_sms_delivery_details_on_deleted_at"
  end

  create_table "user_authentications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id"
    t.string "authenticatable_type"
    t.uuid "authenticatable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["user_id", "authenticatable_type", "authenticatable_id"], name: "user_authentications_master_users_authenticatable_uniq_index", unique: true
    t.index ["user_id"], name: "index_user_authentications_on_user_id"
  end

  create_table "user_permissions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "permission_slug"
    t.string "resource_type"
    t.uuid "resource_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["resource_type", "resource_id"], name: "index_user_permissions_on_resource_type_and_resource_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "full_name"
    t.string "sync_approval_status", null: false
    t.string "sync_approval_status_reason"
    t.datetime "device_updated_at", null: false
    t.datetime "device_created_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.string "role"
    t.uuid "organization_id"
    t.index "to_tsvector('simple'::regconfig, COALESCE((full_name)::text, ''::text))", name: "index_gin_users_on_full_name", using: :gin
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["organization_id"], name: "index_users_on_organization_id"
  end

  add_foreign_key "accesses", "users"
  add_foreign_key "appointments", "facilities"
  add_foreign_key "blood_sugars", "facilities"
  add_foreign_key "blood_sugars", "users"
  add_foreign_key "encounters", "facilities"
  add_foreign_key "exotel_phone_number_details", "patient_phone_numbers"
  add_foreign_key "facilities", "facility_groups"
  add_foreign_key "facility_groups", "organizations"
  add_foreign_key "observations", "encounters"
  add_foreign_key "observations", "users"
  add_foreign_key "patient_phone_numbers", "patients"
  add_foreign_key "patients", "addresses"
  add_foreign_key "patients", "facilities", column: "assigned_facility_id"
  add_foreign_key "patients", "facilities", column: "registration_facility_id"
  add_foreign_key "protocol_drugs", "protocols"

  create_view "blood_pressures_per_facility_per_days", materialized: true, sql_definition: <<-SQL
      WITH latest_bp_per_patient_per_day AS (
           SELECT DISTINCT ON (blood_pressures.facility_id, blood_pressures.patient_id, (date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text, (date_part('doy'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text) blood_pressures.id AS bp_id,
              blood_pressures.facility_id,
              (date_part('doy'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text AS day,
              (date_part('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text AS month,
              (date_part('quarter'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text AS quarter,
              (date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text AS year
             FROM (blood_pressures
               JOIN medical_histories ON (((blood_pressures.patient_id = medical_histories.patient_id) AND (medical_histories.hypertension = 'yes'::text))))
            WHERE (blood_pressures.deleted_at IS NULL)
            ORDER BY blood_pressures.facility_id, blood_pressures.patient_id, (date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text, (date_part('doy'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text, blood_pressures.recorded_at DESC, blood_pressures.id
          )
   SELECT count(latest_bp_per_patient_per_day.bp_id) AS bp_count,
      facilities.id AS facility_id,
      timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, facilities.deleted_at)) AS deleted_at,
      latest_bp_per_patient_per_day.day,
      latest_bp_per_patient_per_day.month,
      latest_bp_per_patient_per_day.quarter,
      latest_bp_per_patient_per_day.year
     FROM (latest_bp_per_patient_per_day
       JOIN facilities ON ((facilities.id = latest_bp_per_patient_per_day.facility_id)))
    GROUP BY latest_bp_per_patient_per_day.day, latest_bp_per_patient_per_day.month, latest_bp_per_patient_per_day.quarter, latest_bp_per_patient_per_day.year, facilities.deleted_at, facilities.id;
  SQL
  add_index "blood_pressures_per_facility_per_days", ["facility_id", "day", "year"], name: "index_blood_pressures_per_facility_per_days", unique: true

  create_view "bp_drugs_views", sql_definition: <<-SQL
      SELECT bp.id AS bp_id,
      bp.systolic,
      bp.diastolic,
      bp.created_at,
      bp.updated_at,
      bp.device_created_at AS visit_date,
      bp.facility_id,
      bp.user_id,
      p.id AS patient_id,
      p.full_name,
      p.age,
      p.gender,
      p.date_of_birth,
      p.status AS patient_status,
      p.address_id,
      p.device_created_at AS registration_date,
      a.street_address,
      a.village_or_colony,
      a.district,
      a.state,
      a.country,
      a.pin,
      f.name AS facility_name,
      f.facility_type,
      f.latitude,
      f.longitude,
      u.full_name AS user_name,
      pn.number AS phone_number,
      pn.phone_type,
      pd.id AS drug_id,
      pd.name AS drug_name,
      pd.rxnorm_code,
      pd.dosage,
      pd.is_protocol_drug,
      pd.is_deleted
     FROM ((((((patients p
       JOIN blood_pressures bp ON ((p.id = bp.patient_id)))
       JOIN facilities f ON ((f.id = bp.facility_id)))
       JOIN addresses a ON ((p.address_id = a.id)))
       JOIN users u ON ((u.id = bp.user_id)))
       LEFT JOIN patient_phone_numbers pn ON ((pn.patient_id = p.id)))
       LEFT JOIN prescription_drugs pd ON (((bp.patient_id = pd.patient_id) AND (date_trunc('day'::text, bp.device_created_at) = date_trunc('day'::text, pd.device_created_at)))));
  SQL
  create_view "bp_views", sql_definition: <<-SQL
      SELECT bp.id AS bp_id,
      bp.systolic,
      bp.diastolic,
      bp.created_at,
      bp.updated_at,
      bp.device_created_at AS visit_date,
      bp.facility_id,
      bp.user_id,
      p.id AS patient_id,
      p.full_name,
      p.age,
      p.gender,
      p.date_of_birth,
      p.status AS patient_status,
      p.address_id,
      p.device_created_at AS registration_date,
      a.street_address,
      a.village_or_colony,
      a.district,
      a.state,
      a.country,
      a.pin,
      f.name AS facility_name,
      f.facility_type,
      f.latitude,
      f.longitude,
      u.full_name AS user_name,
      pn.number AS phone_number,
      pn.phone_type
     FROM (((((patients p
       JOIN blood_pressures bp ON ((p.id = bp.patient_id)))
       JOIN facilities f ON ((f.id = bp.facility_id)))
       JOIN addresses a ON ((p.address_id = a.id)))
       JOIN users u ON ((u.id = bp.user_id)))
       LEFT JOIN patient_phone_numbers pn ON ((pn.patient_id = p.id)));
  SQL
  create_view "follow_up_views", sql_definition: <<-SQL
      SELECT ap.id,
      ap.patient_id,
      ap.facility_id,
      ap.scheduled_date,
      ap.status,
      ap.cancel_reason,
      ap.device_created_at,
      ap.device_updated_at,
      ap.created_at,
      ap.updated_at,
      ap.remind_on,
      ap.agreed_to_visit,
      date_part('day'::text, (lead(ap.device_created_at, 1) OVER (PARTITION BY ap.patient_id ORDER BY ap.scheduled_date) - (ap.scheduled_date)::timestamp without time zone)) AS follow_up_delta,
      f.name AS facility_name,
      f.facility_type,
      f.latitude,
      f.longitude
     FROM (appointments ap
       JOIN facilities f ON ((ap.facility_id = f.id)));
  SQL
  create_view "overdue_views", sql_definition: <<-SQL
      SELECT ap.id AS appointment_id,
      ap.facility_id,
      ap.scheduled_date,
      ap.status AS appointment_status,
      ap.cancel_reason,
      ap.device_created_at,
      ap.device_updated_at,
      ap.created_at,
      ap.updated_at,
      ap.remind_on,
      ap.agreed_to_visit,
      p.id AS patient_id,
      p.full_name,
      p.age,
      p.gender,
      p.date_of_birth,
      p.status AS patient_status,
      p.address_id,
      p.device_created_at AS registration_date,
      a.street_address,
      a.village_or_colony,
      a.district,
      a.state,
      a.country,
      a.pin,
      f.name AS facility_name,
      f.facility_type,
      f.latitude,
      f.longitude
     FROM ((((appointments ap
       JOIN patients p ON ((p.id = ap.patient_id)))
       JOIN facilities f ON ((f.id = ap.facility_id)))
       JOIN addresses a ON ((p.address_id = a.id)))
       LEFT JOIN patient_phone_numbers pn ON ((pn.patient_id = p.id)));
  SQL
  create_view "patient_first_bp_views", sql_definition: <<-SQL
      SELECT bp.id AS bp_id,
      bp.systolic,
      bp.diastolic,
      bp.created_at,
      bp.updated_at,
      bp.device_created_at AS visit_date,
      bp.facility_id,
      bp.user_id,
      p.id AS patient_id,
      p.full_name,
      p.age,
      p.gender,
      p.date_of_birth,
      p.status AS patient_status,
      p.address_id,
      p.device_created_at AS registration_date,
      a.street_address,
      a.village_or_colony,
      a.district,
      a.state,
      a.country,
      a.pin,
      f.name AS facility_name,
      f.facility_type,
      f.latitude,
      f.longitude,
      u.full_name AS user_name,
      pn.number AS phone_number,
      pn.phone_type
     FROM (((((patients p
       LEFT JOIN blood_pressures bp ON (((p.id = bp.patient_id) AND (date_trunc('day'::text, p.device_created_at) = date_trunc('day'::text, bp.device_created_at)))))
       JOIN facilities f ON ((f.id = bp.facility_id)))
       JOIN addresses a ON ((p.address_id = a.id)))
       JOIN users u ON ((u.id = bp.user_id)))
       LEFT JOIN patient_phone_numbers pn ON ((pn.patient_id = p.id)));
  SQL
  create_view "patient_registrations_per_day_per_facilities", materialized: true, sql_definition: <<-SQL
      SELECT count(patients.id) AS registration_count,
      patients.registration_facility_id AS facility_id,
      timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, facilities.deleted_at)) AS deleted_at,
      (date_part('doy'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, patients.recorded_at))))::text AS day,
      (date_part('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, patients.recorded_at))))::text AS month,
      (date_part('quarter'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, patients.recorded_at))))::text AS quarter,
      (date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, patients.recorded_at))))::text AS year
     FROM ((patients
       JOIN facilities ON ((patients.registration_facility_id = facilities.id)))
       JOIN medical_histories ON (((patients.id = medical_histories.patient_id) AND (medical_histories.hypertension = 'yes'::text))))
    WHERE (patients.deleted_at IS NULL)
    GROUP BY (date_part('doy'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, patients.recorded_at))))::text, (date_part('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, patients.recorded_at))))::text, (date_part('quarter'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, patients.recorded_at))))::text, (date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, patients.recorded_at))))::text, patients.registration_facility_id, facilities.deleted_at;
  SQL
  add_index "patient_registrations_per_day_per_facilities", ["facility_id", "day", "year"], name: "index_patient_registrations_per_day_per_facilities", unique: true

  create_view "patient_summaries", sql_definition: <<-SQL
      SELECT p.recorded_at,
      concat(date_part('year'::text, p.recorded_at), ' Q', date_part('quarter'::text, p.recorded_at)) AS registration_quarter,
      p.full_name,
          CASE
              WHEN (p.date_of_birth IS NOT NULL) THEN date_part('year'::text, age((p.date_of_birth)::timestamp with time zone))
              ELSE ((p.age)::double precision + date_part('years'::text, age(now(), (p.age_updated_at)::timestamp with time zone)))
          END AS current_age,
      p.gender,
      p.status,
      latest_phone_number.number AS latest_phone_number,
      addresses.village_or_colony,
      addresses.street_address,
      addresses.district,
      addresses.state,
      reg_facility.name AS registration_facility_name,
      reg_facility.facility_type AS registration_facility_type,
      reg_facility.district AS registration_district,
      reg_facility.state AS registration_state,
      latest_blood_pressure.systolic AS latest_blood_pressure_systolic,
      latest_blood_pressure.diastolic AS latest_blood_pressure_diastolic,
      latest_blood_pressure.recorded_at AS latest_blood_pressure_recorded_at,
      concat(date_part('year'::text, latest_blood_pressure.recorded_at), ' Q', date_part('quarter'::text, latest_blood_pressure.recorded_at)) AS latest_blood_pressure_quarter,
      latest_blood_pressure_facility.name AS latest_blood_pressure_facility_name,
      latest_blood_pressure_facility.facility_type AS latest_blood_pressure_facility_type,
      latest_blood_pressure_facility.district AS latest_blood_pressure_district,
      latest_blood_pressure_facility.state AS latest_blood_pressure_state,
      latest_blood_sugar.blood_sugar_type AS latest_blood_sugar_type,
      latest_blood_sugar.blood_sugar_value AS latest_blood_sugar_value,
      latest_blood_sugar.recorded_at AS latest_blood_sugar_recorded_at,
      concat(date_part('year'::text, latest_blood_sugar.recorded_at), ' Q', date_part('quarter'::text, latest_blood_sugar.recorded_at)) AS latest_blood_sugar_quarter,
      latest_blood_sugar_facility.name AS latest_blood_sugar_facility_name,
      latest_blood_sugar_facility.facility_type AS latest_blood_sugar_facility_type,
      latest_blood_sugar_facility.district AS latest_blood_sugar_district,
      latest_blood_sugar_facility.state AS latest_blood_sugar_state,
      GREATEST((0)::double precision, date_part('day'::text, (now() - (next_appointment.scheduled_date)::timestamp with time zone))) AS days_overdue,
      next_appointment.id AS next_appointment_id,
      next_appointment.scheduled_date AS next_appointment_scheduled_date,
      next_appointment.status AS next_appointment_status,
      next_appointment.remind_on AS next_appointment_remind_on,
      next_appointment_facility.id AS next_appointment_facility_id,
      next_appointment_facility.name AS next_appointment_facility_name,
      next_appointment_facility.facility_type AS next_appointment_facility_type,
      next_appointment_facility.district AS next_appointment_district,
      next_appointment_facility.state AS next_appointment_state,
          CASE
              WHEN (next_appointment.scheduled_date IS NULL) THEN 0
              WHEN (next_appointment.scheduled_date > date_trunc('day'::text, (now() - '30 days'::interval))) THEN 0
              WHEN ((latest_blood_pressure.systolic >= 180) OR (latest_blood_pressure.diastolic >= 110)) THEN 1
              WHEN (((mh.prior_heart_attack = 'yes'::text) OR (mh.prior_stroke = 'yes'::text)) AND ((latest_blood_pressure.systolic >= 140) OR (latest_blood_pressure.diastolic >= 90))) THEN 1
              WHEN ((((latest_blood_sugar.blood_sugar_type)::text = 'random'::text) AND (latest_blood_sugar.blood_sugar_value >= (300)::numeric)) OR (((latest_blood_sugar.blood_sugar_type)::text = 'post_prandial'::text) AND (latest_blood_sugar.blood_sugar_value >= (300)::numeric)) OR (((latest_blood_sugar.blood_sugar_type)::text = 'fasting'::text) AND (latest_blood_sugar.blood_sugar_value >= (200)::numeric)) OR (((latest_blood_sugar.blood_sugar_type)::text = 'hba1c'::text) AND (latest_blood_sugar.blood_sugar_value >= 9.0))) THEN 1
              ELSE 0
          END AS risk_level,
      latest_bp_passport.identifier AS latest_bp_passport,
      p.id
     FROM (((((((((((patients p
       LEFT JOIN addresses ON ((addresses.id = p.address_id)))
       LEFT JOIN facilities reg_facility ON ((reg_facility.id = p.registration_facility_id)))
       LEFT JOIN medical_histories mh ON ((mh.patient_id = p.id)))
       LEFT JOIN ( SELECT DISTINCT ON (patient_phone_numbers.patient_id) patient_phone_numbers.id,
              patient_phone_numbers.number,
              patient_phone_numbers.phone_type,
              patient_phone_numbers.active,
              patient_phone_numbers.created_at,
              patient_phone_numbers.updated_at,
              patient_phone_numbers.patient_id,
              patient_phone_numbers.device_created_at,
              patient_phone_numbers.device_updated_at,
              patient_phone_numbers.deleted_at,
              patient_phone_numbers.dnd_status
             FROM patient_phone_numbers
            ORDER BY patient_phone_numbers.patient_id, patient_phone_numbers.device_created_at DESC) latest_phone_number ON ((latest_phone_number.patient_id = p.id)))
       LEFT JOIN ( SELECT DISTINCT ON (blood_pressures.patient_id) blood_pressures.id,
              blood_pressures.systolic,
              blood_pressures.diastolic,
              blood_pressures.patient_id,
              blood_pressures.created_at,
              blood_pressures.updated_at,
              blood_pressures.device_created_at,
              blood_pressures.device_updated_at,
              blood_pressures.facility_id,
              blood_pressures.user_id,
              blood_pressures.deleted_at,
              blood_pressures.recorded_at
             FROM blood_pressures
            ORDER BY blood_pressures.patient_id, blood_pressures.recorded_at DESC) latest_blood_pressure ON ((latest_blood_pressure.patient_id = p.id)))
       LEFT JOIN facilities latest_blood_pressure_facility ON ((latest_blood_pressure_facility.id = latest_blood_pressure.facility_id)))
       LEFT JOIN ( SELECT DISTINCT ON (blood_sugars.patient_id) blood_sugars.id,
              blood_sugars.blood_sugar_type,
              blood_sugars.blood_sugar_value,
              blood_sugars.patient_id,
              blood_sugars.user_id,
              blood_sugars.facility_id,
              blood_sugars.device_created_at,
              blood_sugars.device_updated_at,
              blood_sugars.deleted_at,
              blood_sugars.recorded_at,
              blood_sugars.created_at,
              blood_sugars.updated_at
             FROM blood_sugars
            ORDER BY blood_sugars.patient_id, blood_sugars.recorded_at DESC) latest_blood_sugar ON ((latest_blood_sugar.patient_id = p.id)))
       LEFT JOIN facilities latest_blood_sugar_facility ON ((latest_blood_sugar_facility.id = latest_blood_sugar.facility_id)))
       LEFT JOIN ( SELECT DISTINCT ON (patient_business_identifiers.patient_id) patient_business_identifiers.id,
              patient_business_identifiers.identifier,
              patient_business_identifiers.identifier_type,
              patient_business_identifiers.patient_id,
              patient_business_identifiers.metadata_version,
              patient_business_identifiers.metadata,
              patient_business_identifiers.device_created_at,
              patient_business_identifiers.device_updated_at,
              patient_business_identifiers.deleted_at,
              patient_business_identifiers.created_at,
              patient_business_identifiers.updated_at
             FROM patient_business_identifiers
            WHERE ((patient_business_identifiers.identifier_type)::text = 'simple_bp_passport'::text)
            ORDER BY patient_business_identifiers.patient_id, patient_business_identifiers.device_created_at DESC) latest_bp_passport ON ((latest_bp_passport.patient_id = p.id)))
       LEFT JOIN ( SELECT DISTINCT ON (appointments.patient_id) appointments.id,
              appointments.patient_id,
              appointments.facility_id,
              appointments.scheduled_date,
              appointments.status,
              appointments.cancel_reason,
              appointments.device_created_at,
              appointments.device_updated_at,
              appointments.created_at,
              appointments.updated_at,
              appointments.remind_on,
              appointments.agreed_to_visit,
              appointments.deleted_at,
              appointments.appointment_type,
              appointments.user_id,
              appointments.creation_facility_id
             FROM appointments
            ORDER BY appointments.patient_id, appointments.scheduled_date DESC) next_appointment ON ((next_appointment.patient_id = p.id)))
       LEFT JOIN facilities next_appointment_facility ON ((next_appointment_facility.id = next_appointment.facility_id)));
  SQL
  create_view "patients_blood_pressures_facilities", sql_definition: <<-SQL
      SELECT patients.id AS p_id,
      patients.age AS p_age,
      patients.gender AS p_gender,
      blood_pressures.id,
      blood_pressures.systolic,
      blood_pressures.diastolic,
      blood_pressures.patient_id,
      blood_pressures.created_at,
      blood_pressures.updated_at,
      blood_pressures.device_created_at,
      blood_pressures.device_updated_at,
      blood_pressures.facility_id,
      blood_pressures.user_id,
      blood_pressures.deleted_at,
      facilities.name,
      facilities.district,
      facilities.state,
      facilities.facility_type,
      users.full_name,
      users.sync_approval_status
     FROM patients,
      blood_pressures,
      facilities,
      users
    WHERE ((blood_pressures.patient_id = patients.id) AND (blood_pressures.facility_id = facilities.id) AND (blood_pressures.user_id = users.id));
  SQL
  create_view "latest_blood_pressures_per_patient_per_days", materialized: true, sql_definition: <<-SQL
      SELECT DISTINCT ON (blood_pressures.patient_id, (date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text, (date_part('doy'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text) blood_pressures.id AS bp_id,
      blood_pressures.patient_id,
      patients.registration_facility_id,
      patients.assigned_facility_id,
      patients.status AS patient_status,
      blood_pressures.facility_id AS bp_facility_id,
      timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at)) AS bp_recorded_at,
      timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, patients.recorded_at)) AS patient_recorded_at,
      blood_pressures.systolic,
      blood_pressures.diastolic,
      timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.deleted_at)) AS deleted_at,
      medical_histories.hypertension AS medical_history_hypertension,
      (date_part('doy'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text AS day,
      (date_part('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text AS month,
      (date_part('quarter'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text AS quarter,
      (date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text AS year
     FROM ((blood_pressures
       JOIN patients ON ((patients.id = blood_pressures.patient_id)))
       LEFT JOIN medical_histories ON ((medical_histories.patient_id = blood_pressures.patient_id)))
    WHERE (blood_pressures.deleted_at IS NULL)
    ORDER BY blood_pressures.patient_id, (date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text, (date_part('doy'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text, blood_pressures.recorded_at DESC, blood_pressures.id;
  SQL
  add_index "latest_blood_pressures_per_patient_per_days", ["bp_id"], name: "index_latest_blood_pressures_per_patient_per_days", unique: true

  create_view "latest_blood_pressures_per_patient_per_months", materialized: true, sql_definition: <<-SQL
      SELECT DISTINCT ON (blood_pressures.patient_id, (date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text, (date_part('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text) blood_pressures.id AS bp_id,
      blood_pressures.patient_id,
      patients.registration_facility_id,
      patients.assigned_facility_id,
      patients.status AS patient_status,
      blood_pressures.facility_id AS bp_facility_id,
      timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at)) AS bp_recorded_at,
      timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, patients.recorded_at)) AS patient_recorded_at,
      blood_pressures.systolic,
      blood_pressures.diastolic,
      timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.deleted_at)) AS deleted_at,
      medical_histories.hypertension AS medical_history_hypertension,
      (date_part('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text AS month,
      (date_part('quarter'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text AS quarter,
      (date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text AS year
     FROM ((blood_pressures
       JOIN patients ON ((patients.id = blood_pressures.patient_id)))
       LEFT JOIN medical_histories ON ((medical_histories.patient_id = blood_pressures.patient_id)))
    WHERE (blood_pressures.deleted_at IS NULL)
    ORDER BY blood_pressures.patient_id, (date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text, (date_part('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text, blood_pressures.recorded_at DESC, blood_pressures.id;
  SQL
  add_index "latest_blood_pressures_per_patient_per_months", ["bp_id"], name: "index_latest_blood_pressures_per_patient_per_months", unique: true

  create_view "latest_blood_pressures_per_patient_per_quarters", materialized: true, sql_definition: <<-SQL
      SELECT DISTINCT ON (latest_blood_pressures_per_patient_per_months.patient_id, latest_blood_pressures_per_patient_per_months.year, latest_blood_pressures_per_patient_per_months.quarter) latest_blood_pressures_per_patient_per_months.bp_id,
      latest_blood_pressures_per_patient_per_months.patient_id,
      latest_blood_pressures_per_patient_per_months.registration_facility_id,
      latest_blood_pressures_per_patient_per_months.assigned_facility_id,
      latest_blood_pressures_per_patient_per_months.patient_status,
      latest_blood_pressures_per_patient_per_months.bp_facility_id,
      latest_blood_pressures_per_patient_per_months.bp_recorded_at,
      latest_blood_pressures_per_patient_per_months.patient_recorded_at,
      latest_blood_pressures_per_patient_per_months.systolic,
      latest_blood_pressures_per_patient_per_months.diastolic,
      latest_blood_pressures_per_patient_per_months.deleted_at,
      latest_blood_pressures_per_patient_per_months.medical_history_hypertension,
      latest_blood_pressures_per_patient_per_months.month,
      latest_blood_pressures_per_patient_per_months.quarter,
      latest_blood_pressures_per_patient_per_months.year
     FROM latest_blood_pressures_per_patient_per_months
    ORDER BY latest_blood_pressures_per_patient_per_months.patient_id, latest_blood_pressures_per_patient_per_months.year, latest_blood_pressures_per_patient_per_months.quarter, latest_blood_pressures_per_patient_per_months.bp_recorded_at DESC, latest_blood_pressures_per_patient_per_months.bp_id;
  SQL
  add_index "latest_blood_pressures_per_patient_per_quarters", ["bp_id"], name: "index_latest_blood_pressures_per_patient_per_quarters", unique: true

  create_view "latest_blood_pressures_per_patients", materialized: true, sql_definition: <<-SQL
      SELECT DISTINCT ON (latest_blood_pressures_per_patient_per_months.patient_id) latest_blood_pressures_per_patient_per_months.bp_id,
      latest_blood_pressures_per_patient_per_months.patient_id,
      latest_blood_pressures_per_patient_per_months.registration_facility_id,
      latest_blood_pressures_per_patient_per_months.assigned_facility_id,
      latest_blood_pressures_per_patient_per_months.patient_status,
      latest_blood_pressures_per_patient_per_months.bp_facility_id,
      latest_blood_pressures_per_patient_per_months.bp_recorded_at,
      latest_blood_pressures_per_patient_per_months.patient_recorded_at,
      latest_blood_pressures_per_patient_per_months.systolic,
      latest_blood_pressures_per_patient_per_months.diastolic,
      latest_blood_pressures_per_patient_per_months.deleted_at,
      latest_blood_pressures_per_patient_per_months.medical_history_hypertension,
      latest_blood_pressures_per_patient_per_months.month,
      latest_blood_pressures_per_patient_per_months.quarter,
      latest_blood_pressures_per_patient_per_months.year
     FROM latest_blood_pressures_per_patient_per_months
    ORDER BY latest_blood_pressures_per_patient_per_months.patient_id, latest_blood_pressures_per_patient_per_months.bp_recorded_at DESC, latest_blood_pressures_per_patient_per_months.bp_id;
  SQL
  add_index "latest_blood_pressures_per_patients", ["bp_id"], name: "index_latest_blood_pressures_per_patients", unique: true

end
