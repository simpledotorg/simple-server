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

    device_created_at { Time.current }
    device_updated_at { Time.current }
  end
end
