FactoryBot.define do
  factory :facility_group do
    transient do
      org { create(:organization) }
    end

    id { SecureRandom.uuid }
    name { Faker::Address.district }
    description { Faker::Company.catch_phrase }
    organization { org }
    protocol

    sequence :slug do |n|
      "#{name.to_s.parameterize.underscore}_#{n}_#{n}"
    end
  end
end
