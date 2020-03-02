require 'rails_helper'

RSpec.describe Api::Current::PatientBusinessIdentifierTransformer do
  describe 'to_response' do
    let(:business_identifier) { FactoryBot.build(:patient_business_identifier) }

    it 'removes patient_id' do
      transformed_business_identifier = Api::Current::PatientBusinessIdentifierTransformer.to_response(business_identifier)

      expect(transformed_business_identifier).not_to include('patient_id')
    end

    it 'transforms metadata to JSON encoded string' do
      transformed_business_identifier = Api::Current::PatientBusinessIdentifierTransformer.to_response(business_identifier)
      transformed_metadata = transformed_business_identifier['metadata']

      expect(transformed_metadata).to be_kind_of(String)
      expect(JSON.parse(transformed_metadata)).to be_kind_of(Hash)
    end
  end

  describe 'from_request' do
    let(:business_identifier_payload) { build_business_identifier_payload }

    it 'transforms JSON encoded metadata string into hash' do
      transformed_payload = Api::Current::PatientBusinessIdentifierTransformer.from_request(business_identifier_payload)
      transformed_metadata = transformed_payload[:metadata]

      expect(transformed_metadata).to be_kind_of(Hash)
    end
  end
end
