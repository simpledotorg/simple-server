# frozen_string_literal: true

FactoryBot.define do
  factory :patient_business_identifier do
    id { SecureRandom.uuid }
    identifier { SecureRandom.uuid }
    identifier_type { "simple_bp_passport" }
    device_created_at { Time.current }
    device_updated_at { Time.current }
    metadata_version { "org.simple.bppassport.meta.v1" }
    metadata do
      {assigning_user_id: SecureRandom.uuid,
       assigning_facility_id: SecureRandom.uuid}
    end

    patient

    trait(:without_metadata) do
      metadata_version { nil }
      metadata { nil }
    end
  end
end

def build_business_identifier_payload(business_identifier = FactoryBot.build(:patient_business_identifier))
  Api::V3::PatientBusinessIdentifierTransformer.to_response(business_identifier)
end
