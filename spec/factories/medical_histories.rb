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
  end
end

def build_medical_history_payload(medical_history = FactoryBot.build(:medical_history))
  medical_history.attributes.with_payload_keys
end

def build_invalid_medical_history_payload
  build_medical_history_payload.merge(
    prior_heart_attack: 'invalid',
    prior_stroke: 'invalid'
  )
end

def updated_medical_history_payload(existing_medical_history)
  update_time = 10.days.from_now

  build_medical_history_payload(existing_medical_history).merge(
    'updated_at' => update_time,
    'prior_heart_attack' => MedicalHistory::MEDICAL_HISTORY_ANSWERS.keys.sample
  )
end