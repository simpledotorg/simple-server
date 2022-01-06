# frozen_string_literal: true

FactoryBot.define do
  factory :facility_business_identifier do
    id { SecureRandom.uuid }
    identifier { SecureRandom.uuid }
    identifier_type { "dhis2_org_unit_id" }

    facility
  end
end
