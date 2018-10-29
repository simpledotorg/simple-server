# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

facilities = [
  { name:          "CHC Nathana",
    facility_type: "CHC",
    district:      "Bathinda",
    state:         "Punjab",
    country:       "India" },

  { name:          "CHC Bagta",
    facility_type: "CHC",
    district:      "Bathinda",
    state:         "Punjab",
    country:       "India" },

  { name:          "CHC Buccho",
    facility_type: "CHC",
    district:      "Bathinda",
    state:         "Punjab",
    country:       "India" },

  { name:          "PHC Meheraj",
    facility_type: "PHC",
    district:      "Bathinda",
    state:         "Punjab",
    country:       "India" },

  { name:          "CHC Khyalakalan",
    facility_type: "CHC",
    district:      "Mansa",
    state:         "Punjab",
    country:       "India" },

  { name:          "PHC Joga",
    facility_type: "PHC",
    district:      "Mansa",
    state:         "Punjab",
    country:       "India" }]

protocol_data = {
  name:           'Punjab Hypertension Protocol',
  follow_up_days: 30
}

protocol_drugs_data = [
  {
    name:   'Amlodipine',
    dosage: '5 mg'
  },
  {
    name:   'Amlodipine',
    dosage: '10 mg'
  },
  {
    name:   'Telmisartan',
    dosage: '40 mg'
  },
  {
    name:   'Telmisartan',
    dosage: '80 mg'
  },
  {
    name:   'Chlorthalidone',
    dosage: '12.5 mg'
  },
  {
    name:   'Chlorthalidone',
    dosage: '25 mg'
  }
]

Facility.destroy_all
User.destroy_all

facilities.each do |facility_data|
  facility = Facility.find_or_create_by(facility_data)

  (1..3).each do |number|
    facility.users.create(
      full_name: "#{facility.name} User #{number}",
      phone_number: rand(1111111111..9999999999),
      password: "1234",
      sync_approval_status: :allowed,
      sync_approval_status_reason: ""
    )
  end
end

protocol = Protocol.find_or_create_by(protocol_data)
protocol_drugs_data.each do |drug_data|
  ProtocolDrug.find_or_create_by(drug_data.merge(protocol_id: protocol.id))
end


### Utils

def rand_facility
  Facility.limit(1).order("RANDOM()").last
end

def rand_user(facility)
  facility.users.limit(1).order("RANDOM()").last
end

def rand_systolic
  rand(100..160)
end

def rand_diastolic
  rand(60..110)
end

def rand_datetime
  rand(90.days.ago..Time.now)
end

def create_bps
  BloodPressure.destroy_all

  Patient.all.each do |patient|
    facility = rand_facility
    patient_date = rand_datetime

    patient.update!(
      device_created_at: patient_date,
      device_updated_at: patient_date,
    )

    rand(1..4).times do
      user = rand_user(facility)
      bp_date = rand_datetime

      patient.blood_pressures.create!(
        id: SecureRandom.uuid,
        user: user,
        facility: facility,
        systolic: rand_systolic,
        diastolic: rand_diastolic,
        device_created_at: bp_date,
        device_updated_at: bp_date
      )
    end
  end
end

create_bps