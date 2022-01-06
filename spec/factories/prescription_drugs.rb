# frozen_string_literal: true

FactoryBot.define do
  factory :prescription_drug do
    id { SecureRandom.uuid }
    sequence(:name) { |n| "#{Faker::Dessert.topping} #{n}" }
    dosage { rand(1..10).to_s + " mg" }
    is_protocol_drug { false }
    is_deleted { false }
    rxnorm_code { Faker::Code.npi }
    device_created_at { Time.current }
    device_updated_at { Time.current }

    patient
    facility
    user

    trait :deleted do
      is_deleted { true }
    end

    trait :protocol do
      is_protocol_drug { true }
    end

    trait :for_teleconsultation do
      frequency { "OD" }
      duration_in_days { 10 }
      association :teleconsultation, strategy: :create
    end
  end
end

def build_prescription_drug_payload(prescription_drug = FactoryBot.build(:prescription_drug))
  prescription_drug.attributes.with_payload_keys
end

def build_invalid_prescription_drug_payload
  build_prescription_drug_payload.merge(
    "created_at" => nil,
    "name" => nil
  )
end

def updated_prescription_drug_payload(existing_prescription_drug)
  update_time = 10.days.from_now
  build_prescription_drug_payload(existing_prescription_drug).merge(
    "updated_at" => update_time,
    "name" => Faker::Dessert.topping
  )
end
