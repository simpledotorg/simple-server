FactoryBot.define do
  factory :facility do
    transient {
      fac_group { create(:facility_group) }
    }

    id { SecureRandom.uuid }
    sequence(:name) { |n| "Facility #{n}" }
    sequence(:street_address) { |n| "#{n} Gandhi Road" }
    sequence(:village_or_colony) { |n| "Colony #{n}" }
    district "Bathinda"
    state "Punjab"
    country "India"
    pin "123456"
    zone "Block ABC"
    facility_type "PHC"
    facility_group { fac_group }
    enable_diabetes_management { true }
  end
end
