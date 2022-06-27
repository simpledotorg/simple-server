FactoryBot.define do
  factory :blood_sugar do
    id { SecureRandom.uuid }
    blood_sugar_type { "random" }
    blood_sugar_value { 150 }
    device_created_at { Time.current }
    device_updated_at { Time.current }
    recorded_at { device_created_at }

    association :facility, strategy: :create
    association :user, strategy: :create
    association :patient, factory: [:patient, :diabetes], strategy: :create

    trait(:with_encounter) do
      after :build do |blood_sugar|
        associate_encounter(blood_sugar)
      end
    end

    trait :with_hba1c do
      blood_sugar_type { BloodSugar.blood_sugar_types.keys.sample }
      blood_sugar_value do
        threshold = BloodSugar::THRESHOLDS[:bs_over_300][:min][blood_sugar_type]
        rand(threshold * 0.9..threshold * 1.1).round(2)
      end
    end

    trait :random do
      blood_sugar_type { "random" }
      blood_sugar_value { 160 }
    end

    trait :post_prandial do
      blood_sugar_type { "post_prandial" }
      blood_sugar_value { 180 }
    end

    trait :fasting do
      blood_sugar_type { "fasting" }
      blood_sugar_value { 140 }
    end

    trait :hba1c do
      blood_sugar_type { "hba1c" }
      blood_sugar_value { 8.5 }
    end

    trait :bs_below_200 do
      blood_sugar_value {
        {random: 150,
         post_prandial: 150,
         fasting: 100,
         hba1c: 6.5}[blood_sugar_type.to_sym]
      }
    end

    trait :bs_200_to_300 do
      blood_sugar_value {
        {random: 250,
         post_prandial: 250,
         fasting: 165,
         hba1c: 8.5}[blood_sugar_type.to_sym]
      }
    end

    trait :bs_over_300 do
      blood_sugar_value {
        {random: 350,
         post_prandial: 350,
         fasting: 225,
         hba1c: 9.5}[blood_sugar_type.to_sym]
      }
    end
  end

  factory :blood_sugar_with_encounter, parent: :blood_sugar do
    with_encounter
  end
end

def build_blood_sugar_payload(blood_sugar = FactoryBot.build(:blood_sugar))
  Api::V3::BloodSugarTransformer.to_response(blood_sugar).with_indifferent_access
end

def build_invalid_blood_sugar_payload
  build_blood_sugar_payload.merge(
    "created_at" => nil,
    "blood_sugar_type" => "invalid"
  )
end

def updated_blood_sugar_payload(existing_blood_sugar)
  update_time = 10.days.from_now
  build_blood_sugar_payload(existing_blood_sugar).merge(
    "updated_at" => update_time,
    "blood_sugar_value" => rand(80..240)
  )
end
