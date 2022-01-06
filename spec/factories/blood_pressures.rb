# frozen_string_literal: true

FactoryBot.define do
  factory :blood_pressure do
    id { SecureRandom.uuid }
    systolic { rand(80..240) }
    diastolic { rand(60..140) }
    device_created_at { Time.current }
    device_updated_at { Time.current }
    recorded_at { device_created_at }

    association :facility, strategy: :create
    association :user, strategy: :create
    association :patient, strategy: :create

    trait(:with_encounter) do
      after :build do |blood_pressure|
        associate_encounter(blood_pressure)
      end
    end

    trait :critical do
      systolic { rand(181..200) }
      diastolic { rand(110..130) }
    end

    trait :hypertensive do
      systolic { rand(140..160) }
      diastolic { rand(90..109) }
    end

    trait :under_control do
      systolic { rand(100..139) }
      diastolic { rand(60..89) }
    end
  end

  # We are making this as a new default BP factory to move to, because many of our tests
  # will depend on the existance of an associated observation / encounter. We don't want to
  # change the main factory as there would be too much test suite fallout.
  factory :bp_with_encounter, parent: :blood_pressure do
    with_encounter
  end
end

def build_blood_pressure_payload(blood_pressure = FactoryBot.build(:blood_pressure))
  Api::V3::Transformer.to_response(blood_pressure).with_indifferent_access
end

def build_invalid_blood_pressure_payload
  build_blood_pressure_payload.merge(
    "created_at" => nil,
    "systolic" => nil,
    "diastolic" => "foo"
  )
end

def updated_blood_pressure_payload(existing_blood_pressure)
  update_time = 10.days.from_now
  build_blood_pressure_payload(existing_blood_pressure).merge(
    "updated_at" => update_time,
    "systolic" => rand(80..240)
  )
end
