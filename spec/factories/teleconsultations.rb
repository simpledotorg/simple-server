FactoryBot.define do
  factory :teleconsultation do
    id { SecureRandom.uuid }

    association :patient, strategy: :create
    association :facility, strategy: :create
    association :requester, factory: :user, strategy: :create
    association :medical_officer, factory: :user, strategy: :create

    requested_at { Time.now }
    request_completed { "yes" }

    recorded_at { Time.now }
    teleconsultation_type { "audio" }
    medical_officer_number { "" }
    patient_took_medicines { "yes" }
    patient_consented { "yes" }
    prescription_drugs { [SecureRandom.uuid, SecureRandom.uuid]}

    device_created_at { Time.current }
    device_updated_at { Time.current }
  end
end

def build_teleconsultation_payload(teleconsultation = FactoryBot.build(:teleconsultation))
  Api::V4::TeleconsultationTransformer.to_response(teleconsultation).with_indifferent_access
end

def build_invalid_teleconsultation_payload
  build_teleconsultation_payload.merge("created_at" => nil)
end

def updated_teleconsultation_payload(existing_teleconsultation)
  update_time = 10.days.from_now
  build_teleconsultation_payload(existing_teleconsultation).merge("updated_at" => update_time)
end
