FactoryBot.define do
  factory :teleconsultation do
    id { SecureRandom.uuid }

    association :patient, strategy: :create
    association :facility, strategy: :create
    association :requester, factory: :user, strategy: :create
    association :medical_officer, factory: :user, strategy: :create

    device_requested_at { Time.now }
    requested_at { device_requested_at }

    recorded_at { device_recorded_at }
    device_recorded_at { Time.now }

    request_completed { "yes" }
    teleconsultation_type { "audio" }
    medical_officer_number { "" }

    patient_took_medicines { true }
    patient_consented { true }

    device_created_at { Time.now }
    device_updated_at { Time.now }
  end
end
