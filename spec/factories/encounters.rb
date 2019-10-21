FactoryBot.define do
  factory :encounter do
    id { SecureRandom.uuid }

    association :patient, strategy: :create
    association :facility, strategy: :create

    transient do
      blood_pressure { create(:blood_pressure) }
    end

    trait(:with_observables) do
      observations { [build(:observation,
                            encounter_id: id,
                            observable: blood_pressure,
                            user: blood_pressure.user)] }
    end

    encountered_on "2019-09-11"

    timezone_offset 0
    metadata nil
    notes ''

    device_created_at { Time.now }
    device_updated_at { Time.now }
  end
end

def build_encounters_payload(encounter = FactoryBot.build(:encounter))
  encounter.attributes.with_payload_keys
    .merge({ :observations =>
               { :blood_pressures => encounter.blood_pressures.map { |bp|
                 bp.attributes.with_payload_keys } } }.with_indifferent_access)
end

def build_invalid_encounters_payload
  encounter = build_encounters_payload
  encounter['created_at'] = nil
  encounter['facility_id'] = nil
  encounter
end

def updated_encounters_payload(existing_encounter)
  update_time = 10.days.from_now
  build_encounters_payload(existing_encounter).merge(
    'updated_at' => update_time,
    'systolic' => rand(80..240)
  )
end


