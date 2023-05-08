FactoryBot.define do
  factory :facility_business_identifier do
    sequence(:id) { |n| n }
    identifier { SecureRandom.uuid }
    identifier_type { "dhis2_org_unit_id" }

    facility
  end
end
