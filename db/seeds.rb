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

facilities.each do |facility_data|
  Facility.find_or_create_by(facility_data)
end

protocol = Protocol.find_or_create_by(protocol_data)
protocol_drugs_data.each do |drug_data|
  ProtocolDrug.find_or_create_by(drug_data.merge(protocol_id: protocol.id))
end