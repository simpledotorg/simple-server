FactoryBot.define do
  factory :encounter do
    association :patient, strategy: :build
    association :facility, strategy: :build

    encountered_on "2019-09-11"

    timezone "Asia/Kolkata"
    timezone_offset 3600
    metadata ""

    recorded_at { Time.now }
    device_created_at { Time.now }
    device_updated_at { Time.now }
  end
end

def build_encounters_payload(encounter = FactoryBot.build(:encounter))
  Api::Current::Transformer.to_response(encounter).with_indifferent_access
end

def build_invalid_encounters_payload
  build_encounter_payload.merge(
    'created_at' => nil,
    'facility_id' => nil)
end


