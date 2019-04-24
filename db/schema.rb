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

ActiveRecord::Schema.define(version: 20190424075016) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "pgcrypto"

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
    t.index ["deleted_at"], name: "index_addresses_on_deleted_at"
  end

  create_table "admin_access_controls", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "admin_id"
    t.uuid "access_controllable_id", null: false
    t.string "access_controllable_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["access_controllable_id", "access_controllable_type"], name: "index_access_controls_on_controllable_id_and_type"
    t.index ["admin_id"], name: "index_admin_access_controls_on_admin_id"
  end

  create_table "admins", force: :cascade do |t|
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "role", default: 0, null: false
    t.string "invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer "invitation_limit"
    t.string "invited_by_type"
    t.bigint "invited_by_id"
    t.integer "invitations_count", default: 0
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_admins_on_deleted_at"
    t.index ["email"], name: "index_admins_on_email", unique: true
    t.index ["invitation_token"], name: "index_admins_on_invitation_token", unique: true
    t.index ["invitations_count"], name: "index_admins_on_invitations_count"
    t.index ["invited_by_id"], name: "index_admins_on_invited_by_id"
    t.index ["invited_by_type", "invited_by_id"], name: "index_admins_on_invited_by_type_and_invited_by_id"
    t.index ["reset_password_token"], name: "index_admins_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_admins_on_unlock_token", unique: true
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
    t.index ["appointment_type"], name: "index_appointments_on_appointment_type"
    t.index ["deleted_at"], name: "index_appointments_on_deleted_at"
    t.index ["facility_id"], name: "index_appointments_on_facility_id"
    t.index ["patient_id"], name: "index_appointments_on_patient_id"
  end

  create_table "audit_logs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "action", null: false
    t.string "auditable_type", null: false
    t.uuid "auditable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["auditable_type", "auditable_id"], name: "index_audit_logs_on_auditable_type_and_auditable_id"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
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
    t.index ["deleted_at"], name: "index_blood_pressures_on_deleted_at"
    t.index ["user_id"], name: "index_blood_pressures_on_user_id"
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
    t.uuid "user_id", null: false
    t.index ["user_id"], name: "index_call_logs_on_user_id"
  end

  create_table "communications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "appointment_id", null: false
    t.uuid "user_id", null: false
    t.string "communication_type"
    t.string "communication_result"
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
    t.index ["id", "detailable_id", "detailable_type"], name: "unique_index_communications_on_detailable", unique: true
    t.index ["user_id"], name: "index_communications_on_user_id"
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
    t.index ["deleted_at"], name: "index_facilities_on_deleted_at"
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
    t.index ["slug"], name: "index_facility_groups_on_slug", unique: true
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
    t.index ["deleted_at"], name: "index_medical_histories_on_deleted_at"
    t.index ["patient_id"], name: "index_medical_histories_on_patient_id"
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
    t.index ["deleted_at"], name: "index_patient_phone_numbers_on_deleted_at"
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
    t.index ["deleted_at"], name: "index_patients_on_deleted_at"
    t.index ["registration_facility_id"], name: "index_patients_on_registration_facility_id"
    t.index ["registration_user_id"], name: "index_patients_on_registration_user_id"
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
    t.index ["deleted_at"], name: "index_prescription_drugs_on_deleted_at"
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
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "full_name"
    t.string "phone_number"
    t.string "password_digest"
    t.datetime "device_created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "device_updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "otp", null: false
    t.datetime "otp_valid_until", null: false
    t.string "access_token", null: false
    t.datetime "logged_in_at"
    t.string "sync_approval_status"
    t.text "sync_approval_status_reason"
    t.datetime "deleted_at"
    t.uuid "registration_facility_id"
    t.index "lower((phone_number)::text)", name: "unique_index_users_on_lowercase_phone_numbers", unique: true
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["registration_facility_id"], name: "index_users_on_registration_facility_id"
  end

  add_foreign_key "appointments", "facilities"
  add_foreign_key "communications", "users"
  add_foreign_key "facilities", "facility_groups"
  add_foreign_key "facility_groups", "organizations"
  add_foreign_key "patient_phone_numbers", "patients"
  add_foreign_key "patients", "addresses"
  add_foreign_key "protocol_drugs", "protocols"
end
