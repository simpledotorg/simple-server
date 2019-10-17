FactoryBot.define do
  factory :prescription_drug do

    id { SecureRandom.uuid }
    name { Faker::Dessert.topping }
    dosage { rand(1..10).to_s + ' mg' }
    is_protocol_drug { [true, false].sample }
    is_deleted { [true, false].sample }
    rxnorm_code { Faker::Code.npi }
    device_created_at { Time.current }
    device_updated_at { Time.current }
    association :facility, strategy: :build
    association :patient, strategy: :build
    user
  end
end

def build_prescription_drug_payload(prescription_drug = FactoryBot.build(:prescription_drug))
  prescription_drug.attributes.with_payload_keys
end

def build_invalid_prescription_drug_payload
  build_prescription_drug_payload.merge(
    'created_at' => nil,
    'name'       => nil
  )
end

def updated_prescription_drug_payload(existing_prescription_drug)
  update_time = 10.days.from_now
  build_prescription_drug_payload(existing_prescription_drug).merge(
    'updated_at' => update_time,
    'name'       => Faker::Dessert.topping
  )
end
