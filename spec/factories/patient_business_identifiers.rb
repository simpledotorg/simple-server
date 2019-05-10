FactoryBot.define do
  factory :patient_business_identifier do
    id { SecureRandom.uuid }
    identifier { SecureRandom.uuid }
    identifier_type { 'simple_bp_passport' }
    device_created_at { Time.now }
    device_updated_at { Time.now }
    recorded_at { device_created_at }
    metadata_version { 'org.simple.bppassport.meta.v1' }
    metadata do
      { assigning_user_id: SecureRandom.uuid,
        assigning_facility_id: SecureRandom.uuid }
    end

    trait(:without_metadata) do
      metadata_version { nil }
      metadata { nil }
    end
  end
end

def build_business_identifier_payload(business_identifier = FactoryBot.build(:patient_business_identifier))
  Api::Current::PatientBusinessIdentifierTransformer.to_response(business_identifier)
end