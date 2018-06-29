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

def common_names
  {
    'english' =>
      { 'female'      => %w[Anjali Divya Ishita Priya Priyanka Riya Shreya Tanvi Tanya Vani],
        'male'        => %w[Abhishek Aditya Amit Ankit Deepak Mahesh Rahul Rohit Shyam Yash],
        'transgender' => %w[Bharathi Madhu Bharathi Manabi Anjum Vani Riya Shreya Kiran Amit],
        'last_name'   => %w[Lamba Bahl Sodhi Sardana Puri Chhabra Khanna Malhotra Mehra Garewal Dhillon]
      },

    'punjabi' =>
      {
        'female'      => %w[ਅੰਜਲੀ ਦਿਵਿਆ ਇਸ਼ਿਤਾ ਪ੍ਰਿਆ ਪ੍ਰਿਯੰਕਾ ਰਿਯਾ ਸ਼੍ਰੇਯਾ ਟਾਂਵੀ ਤੰਯਾ ਵਨੀ],
        'male'        => %w[ਅਭਿਸ਼ੇਕ ਆਦਿਤਿਆ ਅਮਿਤ ਅੰਕਿਤ ਦੀਪਕ ਮਹੇਸ਼ ਰਾਹੁਲ ਰੋਹਿਤ ਸ਼ਿਆਮ ਯਸ਼ ],
        'transgender' => %w[ਭਰਾਠੀ ਮਧੂ ਮਾਨਬੀ ਅੰਜੁਮ ਵਨੀ ਰਿਯਾ ਸ਼੍ਰੇਯਾ ਕਿਰਨ ਅਮਿਤ],
        'last_name'   => %w[ਲੰਬਾ ਬਹਿਲ ਸੋਢੀ ਸਰਦਾਨਾ ਪੂਰੀ ਛਾਬੜਾ ਖੰਨਾ ਮਲਹੋਤਰਾ ਮੇਹਰ ਗਰੇਵਾਲ ਢਿੱਲੋਂ]
      }
  }
end

def common_addresses
  {
    'bathinda' => {
      'english' => {
        street_name:       ['Bhagat singh colony', 'Gandhi Basti', 'NFL Colony', 'Farid Nagari'],
        village_or_colony: %w[Bathinda Bhagwangarh Dannewala Nandgarh Nathana],
      },
      'punjabi' => {
        street_name:       ['ਭਗਤ ਸਿੰਘ ਕਾਲੋਨੀ', 'ਗਾਂਧੀ ਬਸਤੀ', 'ਨਫ਼ਲ ਕਾਲੋਨੀ', 'ਫਰੀਦ ਨਗਰੀ'],
        village_or_colony: %w[ਬਠਿੰਡਾ ਭਗਵੰਗੜ੍ਹ ਡੰਨਵਾਲਾ ਨੰਦਗੜ੍ਹ ਨਥਾਣਾ],
      }
    },
    'mansa'    => {
      'english' => {
        street_name:       ['Bathinda Road', 'Bus Stand Rd', 'Hirke Road', 'Makhewala Jhanduke Road'],
        village_or_colony: ['Bhikhi', 'Budhlada', 'Hirke', 'Jhanduke', 'Mansa', 'Bareta', 'Bhaini Bagha', 'Sadulgarh', 'Sardulewala']
      },
      'punjabi' => {
        street_name:       ['ਬਠਿੰਡਾ ਰੋਡ', 'ਬੱਸ ਸਟੈਂਡ ਰੱਦ', 'ਹੀਰਕੇ ਰੋਡ', 'ਮਖੇਵਾਲਾ ਝੰਡੂਕੇ ਰੋਡ'],
        village_or_colony: ['ਭੀਖੀ', 'ਬੁਢਲਾਡਾ', 'ਹੀਰਕੇ', 'ਝੰਡੂਕੇ', 'ਮਾਨਸਾ', 'ਬਰੇਟਾ', 'ਭੈਣੀ ਬਾਘਾ', 'ਸਾਦੁਲਗੜ੍ਹ', 'ਸਰਦੁਲੇਵਾਲਾ']
      }
    }
  }
end

def random_date(from = 0.0, to = Time.now)
  Time.at(from + rand * (to.to_f - from.to_f))
end

def generate_phone_number
  digits       = (0..9).to_a
  phone_number = ''
  10.times do
    phone_number += digits.sample.to_s
  end
  phone_number
end

def create_random_patient_phone_number(patient_id)
  patient_phone_number = {
    id:                SecureRandom.uuid,
    number:            generate_phone_number,
    phone_type:        PatientPhoneNumber::PHONE_TYPE.sample,
    active:            true,
    patient_id:        patient_id,
    device_created_at: Time.now,
    device_updated_at: Time.now
  }
  PatientPhoneNumber.create(patient_phone_number)
end

def create_random_address(district, language)
  addresses = common_addresses[district][language]
  address   = {
    id:                SecureRandom.uuid,
    street_address:    "# #{rand(100)}, #{addresses[:street_name].sample}",
    village_or_colony: addresses[:village_or_colony].sample,
    district:          district,
    state:             language == 'punjabi' ? 'ਪੰਜਾਬ' : 'Punjab',
    country:           language == 'punjabi' ? 'ਇੰਡੀਆ' : 'India',
    pin:               district == 'bathinda' ? "1510#{rand(100)}" : "1515#{rand(100)}",
    device_created_at: Time.now,
    device_updated_at: Time.now
  }
  Address.create(address)
end

def create_random_patient(address_id, language)
  has_age   = [true, false].sample
  gender    = Patient::GENDERS.sample
  full_name = "#{common_names[language][gender].sample} #{common_names[language]['last_name'].sample}"
  patient   = {
    id:                SecureRandom.uuid,
    gender:            gender,
    full_name:         full_name,
    status:            'testdata',
    age:               has_age ? rand(18..100) : nil,
    age_updated_at:    has_age ? Time.now : nil,
    address_id:        address_id,
    date_of_birth:     !has_age ? random_date : nil,
    device_created_at: Time.now,
    device_updated_at: Time.now
  }

  Patient.create(patient)
end

if FeatureToggle.enabled?('PATIENT_TEST_DATA')
  max_patient_phone_numbers      = 3
  number_of_patients_to_generate = 100

  number_of_patients_to_generate.times do
    district = common_addresses.keys.sample
    language = common_addresses[district].keys.sample
    address  = create_random_address(district, language)
    patient  = create_random_patient(address.id, language)
    max_patient_phone_numbers.times do
      create_random_patient_phone_number(patient.id)
    end
  end
end