FactoryBot.define do
  factory :facility do
    transient do
      fac_group { create(:facility_group) }
    end

    id { SecureRandom.uuid }
    sequence(:name) { |n| "Facility #{n}" }
    sequence(:street_address) { |n| "#{n} Gandhi Road" }
    sequence(:village_or_colony) { |n| "Colony #{n}" }
    district 'Bathinda'
    state 'Punjab'
    country 'India'
    pin '123456'
    zone 'Block ABC'
    facility_type 'PHC'
    facility_size { Facility.facility_sizes[:small] }
    facility_group { fac_group }
    enable_diabetes_management { true }
    monthly_opd_load 300
  end
end
