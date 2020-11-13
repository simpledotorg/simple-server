FactoryBot.define do
  factory :facility do
    id { SecureRandom.uuid }
    sequence(:name) { |n| "Facility #{n}" }
    sequence(:street_address) { |n| "#{n} Gandhi Road" }
    sequence(:village_or_colony) { |n| "Colony #{n}" }
    district { "Bathinda" }
    state { "Punjab" }
    country { "India" }
    pin { "123456" }
    zone { Faker::Address.community }
    facility_type { "PHC" }
    facility_size { Facility.facility_sizes[:small] }
    facility_group { create(:facility_group) }
    enable_diabetes_management { [true, false].sample }
    enable_teleconsultation { false }
    monthly_estimated_opd_load { 300 }

    trait :with_teleconsultation do
      enable_teleconsultation { true }
      teleconsultation_medical_officers { [create(:user)] }
    end

    trait :seed do
      name { "#{facility_type} #{village_or_colony}" }
      street_address { Faker::Address.street_address }
      village_or_colony { Faker::Address.village }
      district { Faker::Address.district }
      state { Faker::Address.state }
      country { "India" }
      pin { Faker::Address.zip_code }
      zone { Faker::Address.block }
      facility_type { "PHC" }
    end

    transient do
      create_parent_region { Flipper.enabled?(:regions_prep) }
    end

    before(:create) { |f, options|
      create(:region,
        name: f.zone,
        region_type: :block,
        reparent_to: f.facility_group.region) if options.create_parent_region
    }

    trait :without_parent_region do
      create_parent_region { false }
    end
  end
end
