FactoryBot.define do
  factory :patient do
    common_names = { 'female'      => %w[anjali divya ishita priya priyanka riya shreya tanvi tanya vani],
                     'male'        => %w[abhishek adityaamit ankit deepak mahesh rahul rohit shyam yash],
                     'transgender' => %w[bharathi madhu bharathi manabi anjum vani riya shreya kiran amit] }

    transient do
      has_date_of_birth? { [true, false].sample }
    end

    id { SecureRandom.uuid }
    gender { Patient::GENDERS.sample }
    full_name { common_names[gender].sample + " " + common_names[gender].sample }
    status { Patient::STATUSES.sample }
    date_of_birth { Date.today if has_date_of_birth? }
    age_when_created { rand(18..100) unless has_date_of_birth? }
    created_at { Time.now }
    updated_at { Time.now }
    updated_on_server_at { Time.now }
    association :address, strategy: :build
    after :build do |patient|
      patient.phone_numbers = build_list(:phone_number, (rand 0..3))
      patient.patient_phone_numbers.each { |phno| phno.updated_on_server_at = Time.now }
    end
  end
end

def build_patient_payload(patient = FactoryBot.build(:patient))
  address       = patient.address
  phone_numbers = patient.phone_numbers
  payload       = patient.attributes.merge(
    'address'       => address.attributes.except('updated_on_server_at'),
    'phone_numbers' => phone_numbers.map { |phno| phno.attributes.except('updated_on_server_at') }
  ).except('address_id', 'updated_on_server_at')
end

def build_invalid_patient_payload
  patient                          = build_patient_payload
  patient['created_at']            = nil
  patient['address']['created_at'] = nil
  patient['phone_numbers'].each do |phone_number|
    phone_number.merge!('created_at' => nil)
  end
  patient
end

def updated_patient_payload(existing_patient)
  phone_number = existing_patient.phone_numbers.sample || FactoryBot.build(:phone_number)
  update_time  = 10.days.from_now
  build_patient_payload(existing_patient).deep_merge(
    'full_name'     => Faker::Name.name,
    'updated_at'    => update_time,
    'address'       => { 'updated_at'     => update_time,
                         'street_address' => Faker::Address.street_address },
    'phone_numbers' => [phone_number.attributes.merge(
      'updated_at' => update_time,
      'number'     => Faker::PhoneNumber.phone_number).except('updated_on_server_at')]
  )
end