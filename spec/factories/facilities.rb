FactoryBot.define do
  factory :facility do
    transient do
      village { Faker::Address.village }
    end

    id { SecureRandom.uuid }
    name { "#{facility_type} #{village}" }
    street_address { Faker::Address.street_address }
    village_or_colony { village }
    district { Faker::Address.district }
    state { Faker::Address.state }
    country { 'India' }
    pin { Faker::Address.zip_code }
    zone { Faker::Address.block }
    facility_type { 'PHC' }
    facility_size { Facility.facility_sizes[:small] }
    facility_group { create(:facility_group) }
    enable_diabetes_management { true }
  end
end
