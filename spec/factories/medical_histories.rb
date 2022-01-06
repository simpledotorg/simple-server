# frozen_string_literal: true

FactoryBot.define do
  factory :medical_history do
    id { SecureRandom.uuid }
    association :patient, strategy: :build
    prior_heart_attack { MedicalHistory::MEDICAL_HISTORY_ANSWERS[:no] }
    prior_stroke { MedicalHistory::MEDICAL_HISTORY_ANSWERS[:no] }
    chronic_kidney_disease { MedicalHistory::MEDICAL_HISTORY_ANSWERS[:no] }
    receiving_treatment_for_hypertension { MedicalHistory::MEDICAL_HISTORY_ANSWERS[:no] }
    receiving_treatment_for_diabetes { MedicalHistory::MEDICAL_HISTORY_ANSWERS[:no] }
    diabetes { MedicalHistory::MEDICAL_HISTORY_ANSWERS[:no] }
    hypertension { MedicalHistory::MEDICAL_HISTORY_ANSWERS[:no] }
    diagnosed_with_hypertension { MedicalHistory::MEDICAL_HISTORY_ANSWERS[:no] }
    device_created_at { Time.current }
    device_updated_at { Time.current }
    user

    trait :unknown do
      prior_heart_attack { MedicalHistory::MEDICAL_HISTORY_ANSWERS[:unknown] }
      prior_stroke { MedicalHistory::MEDICAL_HISTORY_ANSWERS[:unknown] }
      chronic_kidney_disease { MedicalHistory::MEDICAL_HISTORY_ANSWERS[:unknown] }
      receiving_treatment_for_hypertension { MedicalHistory::MEDICAL_HISTORY_ANSWERS[:unknown] }
      receiving_treatment_for_diabetes { MedicalHistory::MEDICAL_HISTORY_ANSWERS[:unknown] }
      diabetes { MedicalHistory::MEDICAL_HISTORY_ANSWERS[:unknown] }
      hypertension { MedicalHistory::MEDICAL_HISTORY_ANSWERS[:unknown] }
      diagnosed_with_hypertension { MedicalHistory::MEDICAL_HISTORY_ANSWERS[:unknown] }
    end

    trait :hypertension_yes do
      hypertension { MedicalHistory::MEDICAL_HISTORY_ANSWERS[:yes] }
    end

    trait :hypertension_no do
      hypertension { MedicalHistory::MEDICAL_HISTORY_ANSWERS[:no] }
    end

    trait :hypertension_unknown do
      hypertension { MedicalHistory::MEDICAL_HISTORY_ANSWERS[:unknown] }
    end

    trait :diabetes_yes do
      diabetes { MedicalHistory::MEDICAL_HISTORY_ANSWERS[:yes] }
    end

    trait :diabetes_no do
      diabetes { MedicalHistory::MEDICAL_HISTORY_ANSWERS[:no] }
    end

    trait :diabetes_unknown do
      diabetes { MedicalHistory::MEDICAL_HISTORY_ANSWERS[:unknown] }
    end

    trait :prior_risk_history do
      prior_heart_attack_boolean { true }
      prior_stroke_boolean { true }
      diabetes_boolean { true }
      chronic_kidney_disease_boolean { true }

      prior_heart_attack { "yes" }
      prior_stroke { "yes" }
      diabetes { "yes" }
      hypertension { "yes" }
      chronic_kidney_disease { "yes" }
    end
  end
end

# Payloads for v3 API

def build_medical_history_payload(medical_history = FactoryBot.build(:medical_history))
  medical_history.attributes.with_payload_keys
end

def build_invalid_medical_history_payload
  build_medical_history_payload.merge(
    prior_heart_attack: "invalid",
    prior_stroke: "invalid"
  )
end

def updated_medical_history_payload(existing_medical_history)
  update_time = 10.days.from_now

  build_medical_history_payload(existing_medical_history).merge(
    "updated_at" => update_time,
    "prior_heart_attack" => MedicalHistory::MEDICAL_HISTORY_ANSWERS.values.sample
  )
end
