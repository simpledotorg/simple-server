FactoryBot.define do
  factory :facility_group do
    transient do
      org_name { create(:organization) }
      state_name { Faker::Address.state }
    end

    id { SecureRandom.uuid }
    name { Faker::Address.district }
    description { Faker::Company.catch_phrase }
    organization { org_name }
    state { state_name }
    protocol

    # create the parent region
    before(:create) { |fg| create(:region, name: fg.state, region_type: :state, reparent_to: fg.organization.region) }
  end
end
