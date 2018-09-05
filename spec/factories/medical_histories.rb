FactoryBot.define do
  factory :medical_history do
    id { SecureRandom.uuid }
    association :patient, strategy: :build
    has_prior_heart_attack { false }
    has_prior_stroke { false }
    has_chronic_kidney_disease { false }
    is_on_treatment_for_hypertension { false }
    device_created_at { Time.now }
    device_updated_at { Time.now }
  end
end

def build_medical_history_payload(medical_history = FactoryBot.build(:medical_history))
  medical_history.attributes.with_payload_keys
end

def build_invalid_medical_history_payload
  build_medical_history_payload.merge(
    has_prior_heart_attack: nil,
    has_prior_stroke: nil
  )
end

def updated_medical_history_payload(existing_medical_history)
  update_time = 10.days.from_now

  build_medical_history_payload(existing_medical_history).merge(
    'updated_at' => update_time,
    'has_prior_heart_attack' => !existing_medical_history.has_prior_heart_attack
  )
end