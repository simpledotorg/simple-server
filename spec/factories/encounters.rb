FactoryBot.define do
  factory :encounter do
    id { SecureRandom.uuid }
    association :patient, strategy: :create
    association :facility, strategy: :create

    encountered_on "2019-09-11"

    timezone_offset 3600
    metadata ""
    notes ""

    device_created_at { Time.now }
    device_updated_at { Time.now }
  end
end

def build_encounters_payload(encounter = FactoryBot.build(:encounter))
  encounter.attributes.with_payload_keys
    .merge('observations' =>
             { 'blood_pressures' => encounter.blood_pressures.map { |bp|
               bp.attributes.with_payload_keys } })
end

def build_invalid_encounters_payload
  encounter = build_encounters_payload
  encounter['created_at'] = nil
  encounter['facility_id'] = nil
  encounter
end

