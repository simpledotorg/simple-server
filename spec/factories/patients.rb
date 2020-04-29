FactoryBot.define do
  factory :patient do
    common_names = { 'female' => %w[Anjali Divya Ishita Priya Priyanka Riya Shreya Tanvi Tanya Vani],
                     'male' => %w[Abhishek Aditya Amit Ankit Deepak Mahesh Rahul Rohit Shyam Yash],
                     'transgender' => %w[Bharathi Madhu Bharathi Manabi Anjum Vani Riya Shreya Kiran Amit] }

    transient do
      has_date_of_birth? { [true, false].sample }
    end

    id { SecureRandom.uuid }
    gender { Patient::GENDERS.sample }
    full_name { common_names[gender].sample + ' ' + common_names[gender].sample }
    status { Patient::STATUSES[0] }
    date_of_birth { Date.current if has_date_of_birth? }
    age { rand(18..100) unless has_date_of_birth? }
    age_updated_at { Time.current }
    device_created_at { Time.current }
    device_updated_at { Time.current }
    recorded_at { device_created_at }
    association :address, strategy: :build
    phone_numbers { build_list(:patient_phone_number, 1, patient_id: id) }
    association :registration_facility, factory: :facility
    association :registration_user, factory: :user_created_on_device
    business_identifiers do
      build_list(:patient_business_identifier,
                 1,
                 patient_id: id,
                 metadata: {assigning_facility_id: registration_facility.id,
                            assigning_user_id: registration_user.id})
    end
    reminder_consent { Patient.reminder_consents[:granted] }

    trait :denied do
      reminder_consent { Patient.reminder_consents[:denied] }
    end

    trait(:with_sanitized_phone_number) do
      phone_numbers { build_list(:patient_phone_number, 1, patient_id: id, number: '9876543210') }
    end
  end
end

def build_patient_payload(patient = FactoryBot.build(:patient))
  patient.attributes.with_payload_keys
      .except('address_id')
      .except('registration_user_id')
      .except('registration_facility_id')
      .except('test_data')
      .merge(
        'address' => patient.address.attributes.with_payload_keys,
        'phone_numbers' => patient.phone_numbers.map { |phno| phno.attributes.with_payload_keys.except('patient_id', 'dnd_status') },
        'business_identifiers' => patient.business_identifiers.map do |bid|
          bid.attributes.with_payload_keys
            .except('patient_id')
            .merge('metadata' => bid.metadata&.to_json)
        end
     )
end

def build_patient_payload_v2(patient = FactoryBot.build(:patient))
  payload = build_patient_payload(patient)
  payload.merge('address' => payload['address'].except('zone'))
    .except('recorded_at')
    .except('reminder_consent')
end

def build_invalid_patient_payload
  patient = build_patient_payload
  patient['created_at'] = nil
  patient['address']['created_at'] = nil
  patient['phone_numbers'].each do |phone_number|
    phone_number.merge!('created_at' => nil)
  end
  patient
end

def updated_patient_payload(existing_patient)
  phone_number = existing_patient.phone_numbers.sample || FactoryBot.build(:patient_phone_number, patient: existing_patient)
  business_identifier = existing_patient.business_identifiers.sample || FactoryBot.build(:patient_business_identifier, patient: existing_patient)
  update_time = 10.days.from_now
  build_patient_payload(existing_patient).deep_merge(
    'full_name' => Faker::Name.name,
    'updated_at' => update_time,
    'address' => { 'updated_at' => update_time,
                   'street_address' => Faker::Address.street_address },
    'phone_numbers' => [phone_number.attributes.with_payload_keys.merge(
      'updated_at' => update_time,
      'number' => Faker::PhoneNumber.phone_number
    )],
    'business_identifiers' => [business_identifier.attributes.with_payload_keys.merge(
      'updated_at' => update_time,
      'identifier' => SecureRandom.uuid,
      'metadata' => business_identifier.metadata&.to_json
    )]
  )
end

def updated_patient_payload_v2(existing_patient)
  updated_patient_payload(existing_patient)
    .except('recorded_at')
end
