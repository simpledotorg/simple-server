FactoryBot.define do
  factory :medical_history do
    id { SecureRandom.uuid }
    association :patient, strategy: :build
    prior_heart_attack { MedicalHistory::MEDICAL_HISTORY_ANSWERS[:no] }
    prior_stroke { MedicalHistory::MEDICAL_HISTORY_ANSWERS[:no] }
    chronic_kidney_disease { MedicalHistory::MEDICAL_HISTORY_ANSWERS[:no] }
    receiving_treatment_for_hypertension { MedicalHistory::MEDICAL_HISTORY_ANSWERS[:no] }
    diabetes { MedicalHistory::MEDICAL_HISTORY_ANSWERS[:no] }
    diagnosed_with_hypertension { MedicalHistory::MEDICAL_HISTORY_ANSWERS[:no] }
    device_created_at { Time.now }
    device_updated_at { Time.now }
    recorded_at { device_created_at }

    trait :unknown do
      prior_heart_attack { MedicalHistory::MEDICAL_HISTORY_ANSWERS[:unknown] }
      prior_stroke { MedicalHistory::MEDICAL_HISTORY_ANSWERS[:unknown] }
      chronic_kidney_disease { MedicalHistory::MEDICAL_HISTORY_ANSWERS[:unknown] }
      receiving_treatment_for_hypertension { MedicalHistory::MEDICAL_HISTORY_ANSWERS[:unknown] }
      diabetes { MedicalHistory::MEDICAL_HISTORY_ANSWERS[:unknown] }
      diagnosed_with_hypertension { MedicalHistory::MEDICAL_HISTORY_ANSWERS[:unknown] }
    end

    trait :prior_risk_history do
      prior_heart_attack_boolean { true }
      prior_stroke_boolean { true }
      diabetes_boolean { true }
      chronic_kidney_disease_boolean { true }
    end
  end
end

# Payloads for current API

def build_medical_history_payload_current(medical_history = FactoryBot.build(:medical_history))
  medical_history.attributes.with_payload_keys
end

def build_invalid_medical_history_payload_current
  build_medical_history_payload_current.merge(
    prior_heart_attack: 'invalid',
    prior_stroke: 'invalid'
  )
end

def updated_medical_history_payload_current(existing_medical_history)
  update_time = 10.days.from_now

  build_medical_history_payload_current(existing_medical_history).merge(
    'updated_at' => update_time,
    'prior_heart_attack' => MedicalHistory::MEDICAL_HISTORY_ANSWERS.values.sample
  )
end

# Payloads for v2 API

def build_medical_history_payload_v2(medical_history = FactoryBot.build(:medical_history))
  medical_history.attributes.with_payload_keys
end

def build_invalid_medical_history_payload_v2
  build_medical_history_payload_v2.merge(
    prior_heart_attack: 'invalid',
    prior_stroke: 'invalid'
  )
end

def updated_medical_history_payload_v2(existing_medical_history)
  update_time = 10.days.from_now

  build_medical_history_payload_v2(existing_medical_history).merge(
    'updated_at' => update_time,
    'prior_heart_attack' => MedicalHistory::MEDICAL_HISTORY_ANSWERS.values.sample
  )
end

# Payloads for V1 API

def build_medical_history_payload_v1(medical_history = FactoryBot.build(:medical_history))
  Api::V1::MedicalHistoryTransformer.to_response(medical_history).with_indifferent_access
end

def build_invalid_medical_history_payload_v1
  build_medical_history_payload_v1.merge(
    prior_heart_attack: nil,
    prior_stroke: nil
  )
end

def updated_medical_history_payload_v1(existing_medical_history)
  update_time = 10.days.from_now

  build_medical_history_payload_v1(existing_medical_history).merge(
    'updated_at' => update_time,
    'prior_heart_attack' => MedicalHistory::MEDICAL_HISTORY_ANSWERS.keys.sample
  )
end
