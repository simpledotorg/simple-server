FactoryBot.define do
  factory :patient_business_identifier do
    id { SecureRandom.uuid }
    identifier { SecureRandom.uuid }
    identifier_type { 'simple_bp_passport' }
    device_created_at { Time.now }
    device_updated_at { Time.now }

    trait(:with_metadata) do
      metadata_version { 'org.simple.bppassport.meta.v1' }
      metadata do
        { assigning_user_id: SecureRandom.uuid,
          assigning_facility_id: SecureRandom.uuid }
      end
    end
  end
end
