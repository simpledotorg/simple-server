require 'swagger_helper'

describe 'PrescriptionDrugs API' do

  path '/prescription_drugs/sync' do

    post 'Syncs prescription drugs data from device to server.' do
      tags 'Prescription Drug'
      parameter name: :prescription_drugs, in: :body, schema: Api::V1::Schema.prescription_drug_sync_from_user_request

      response '200', 'blood pressures created' do
        let(:prescription_drugs) { { prescription_drugs: (1..10).map { build_prescription_drug_payload } } }
        run_test!
      end

      response '200', 'some, or no errors were found' do
        schema Api::V1::Schema.sync_from_user_errors
        let(:prescription_drugs) { { prescription_drugs: (1..10).map { build_invalid_prescription_drug_payload } } }
        run_test!
      end
    end

    get 'Syncs prescription drugs data from server to device.' do
      tags 'Prescription Drug'
      Api::V1::Schema.sync_to_user_request.each do |param|
        parameter param
      end

      before :each do
        Timecop.travel(10.minutes.ago) do
          FactoryBot.create_list(:prescription_drug, 10)
        end
      end

      response '200', 'blood pressures received' do
        schema Api::V1::Schema.prescription_drug_sync_to_user_response
        let(:processed_since) { 10.minutes.ago }
        let(:limit) { 10 }
        run_test!
      end
    end
  end
end