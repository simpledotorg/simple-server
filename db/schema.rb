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

ActiveRecord::Schema.define(version: 20180510102039) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "addresses", id: :uuid, default: nil, force: :cascade do |t|
    t.string "street_address"
    t.string "colony"
    t.string "village"
    t.string "district"
    t.string "state"
    t.string "country"
    t.string "pin"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "patients", id: :uuid, default: nil, force: :cascade do |t|
    t.string "full_name"
    t.integer "age_when_created"
    t.string "gender"
    t.date "date_of_birth"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "address_id"
  end

  create_table "patients_phone_numbers", id: false, force: :cascade do |t|
    t.uuid "patient_id"
    t.uuid "phone_number_id"
    t.index ["phone_number_id", "patient_id"], name: "index_patients_phone_numbers_on_phone_number_id_and_patient_id", unique: true
  end

  create_table "phone_numbers", id: :uuid, default: nil, force: :cascade do |t|
    t.string "number"
    t.string "type"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "patients", "addresses"
end
