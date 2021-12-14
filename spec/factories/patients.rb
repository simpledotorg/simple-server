FactoryBot.define do
  factory :patient do
    common_names = {female: %w[Anjali Divya Ishita Priya Priyanka Riya Shreya Tanvi Tanya Vani],
                    male: %w[Abhishek Aditya Amit Ankit Deepak Mahesh Rahul Rohit Shyam Yash],
                    transgender: %w[Bharathi Madhu Bharathi Manabi Anjum Vani Riya Shreya Kiran Amit]}

    id { SecureRandom.uuid }
    gender { Seed::Gender.random_gender }
    full_name { common_names[gender.to_sym].sample + " " + common_names[gender.to_sym].sample }
    status { Patient::STATUSES[0] }
    date_of_birth { nil }
    age { rand(18..100) }
    age_updated_at { Time.current }
    device_created_at { Time.current }
    device_updated_at { Time.current }
    recorded_at { device_created_at }
    association :address, strategy: :build
    phone_numbers do
      [association(:patient_phone_number, strategy: :build, patient: instance)]
    end
    association :registration_facility, factory: :facility
    assigned_facility { registration_facility }
    association :registration_user, factory: :user_created_on_device
    business_identifiers do
      [association(:patient_business_identifier, strategy: :build, patient: instance,
                                                 metadata: {assigning_facility_id: registration_facility.id, assigning_user_id: registration_user.id})]
    end
    reminder_consent { Patient.reminder_consents[:granted] }
    medical_history { build(:medical_history, :hypertension_yes, patient_id: id, user: registration_user) }

    trait(:with_dob) do
      date_of_birth { rand(18..80).years.ago }
      age { nil }
      age_updated_at { nil }
    end

    trait :without_hypertension do
      medical_history { build(:medical_history, :hypertension_no, patient_id: id) }
    end

    trait :diabetes do
      medical_history { build(:medical_history, :diabetes_yes, patient_id: id) }
    end

    trait :hypertension do
      medical_history { build(:medical_history, :hypertension_yes, patient_id: id) }
    end

    trait :without_medical_history do
      medical_history { nil }
    end

    trait :denied do
      reminder_consent { Patient.reminder_consents[:denied] }
    end

    trait(:seed) do
      business_identifiers { nil }
    end

    trait(:with_sanitized_phone_number) do
      phone_numbers { build_list(:patient_phone_number, 1, patient_id: id, number: "9876543210") }
    end

    trait(:with_appointments) do
      appointments { build_list(:appointment, 2, facility: registration_facility) }
    end

    trait(:with_overdue_appointments) do
      appointments { build_list(:appointment, 2, :overdue, facility: registration_facility) }
    end
  end
end

def build_patient_payload(patient = FactoryBot.build(:patient))
  patient.attributes.with_payload_keys
    .except("address_id")
    .except("registration_user_id")
    .except("test_data")
    .except("deleted_by_user_id")
    .merge(
      "address" => patient.address.attributes.with_payload_keys,
      "phone_numbers" => patient.phone_numbers.map { |phno| phno.attributes.with_payload_keys.except("patient_id", "dnd_status") },
      "business_identifiers" => patient.business_identifiers.map do |bid|
        bid.attributes.with_payload_keys
          .except("patient_id")
          .merge("metadata" => bid.metadata&.to_json)
      end
    )
end

def build_invalid_patient_payload
  patient = build_patient_payload
  patient["created_at"] = nil
  patient["address"]["created_at"] = nil
  patient["phone_numbers"].each do |phone_number|
    phone_number.merge!("created_at" => nil)
  end
  patient
end

def updated_patient_payload(existing_patient)
  phone_number = existing_patient.phone_numbers.sample || FactoryBot.build(:patient_phone_number, patient: existing_patient)
  business_identifier = existing_patient.business_identifiers.sample || FactoryBot.build(:patient_business_identifier, patient: existing_patient)
  update_time = 10.days.from_now
  build_patient_payload(existing_patient).deep_merge(
    "full_name" => Faker::Name.name,
    "updated_at" => update_time,
    "address" => {"updated_at" => update_time,
                  "street_address" => Faker::Address.street_address},
    "phone_numbers" => [phone_number.attributes.with_payload_keys.merge(
      "updated_at" => update_time,
      "number" => Faker::PhoneNumber.phone_number
    )],
    "business_identifiers" => [business_identifier.attributes.with_payload_keys.merge(
      "updated_at" => update_time,
      "identifier" => SecureRandom.uuid,
      "metadata" => business_identifier.metadata&.to_json
    )]
  )
end

def create_visit(patient, facility: patient.registration_facility, user: patient.registration_user, visited_at: Time.now)
  patient.prescription_drugs.where("device_created_at < ?", visited_at).update_all(is_deleted: true)
  patient.appointments.where("device_created_at < ?", visited_at).update_all(status: :visited)
  {
    blood_pressure: create(:blood_pressure, :with_encounter, :critical, recorded_at: visited_at, facility: facility, patient: patient, user: user),
    blood_sugar: create(:blood_sugar, :fasting, :with_encounter, recorded_at: visited_at, facility: facility, patient: patient, user: user),
    protocol_prescription_drug: create(:prescription_drug, :protocol, device_created_at: visited_at, facility: facility, patient: patient, user: user),
    non_protocol_prescription_drug: create(:prescription_drug, device_created_at: visited_at, facility: facility, patient: patient, user: user),
    appointment: create(:appointment, status: :scheduled, device_created_at: visited_at, scheduled_date: 1.month.after(visited_at), creation_facility: facility, facility: facility, patient: patient, user: user),
    teleconsultation: create(:teleconsultation, patient: patient, facility: facility, requester: user, medical_officer: user, requested_medical_officer: user)
  }
end

def add_visits(visit_count, patient:, facility: patient.registration_facility, user: patient.registration_user)
  (1..visit_count).to_a.reverse_each do |num_months|
    create_visit(patient, facility: facility, user: user, visited_at: num_months.months.ago)
  end
end

def create_patient_with_visits(registration_time: Time.now, facility: create(:facility), user: create(:admin, :power_user))
  patient = create(:patient,
    recorded_at: registration_time,
    registration_facility: facility,
    registration_user: user,
    device_created_at: registration_time,
    device_updated_at: registration_time)

  add_visits(3, patient: patient, facility: facility, user: user)

  patient
end
