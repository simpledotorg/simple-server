require 'swagger_helper'

describe 'Patients API' do

  path '/patients/sync' do

    post 'Syncs patient, address and phone number data from device to server.' do
      tags 'patient'
      parameter name: :patients, in: :body, schema: Api::V1::Spec.patient_sync_from_user_request_spec

      response '200', 'patients created' do
        let(:patients) { { patients: (1..10).map { build_patient_payload } } }
        run_test!
      end

      response '200', 'some, or no errors were found' do
        schema Api::V1::Spec.patient_sync_from_user_errors_spec
        let(:patients) { { patients: (1..10).map { build_invalid_patient_payload } } }
        run_test!
      end
    end

    get 'Syncs patient, address and phone number data from server to device.' do
      tags 'patient'
      Api::V1::Spec.patient_sync_to_user_request_spec.each do |param|
        parameter param
      end

      before :each do
        Timecop.travel(10.minutes.ago) do
          FactoryBot.create_list(:patient, 10)
        end
      end

      response '200', 'patients received' do
        schema Api::V1::Spec.patient_sync_to_user_response_spec
        let(:processed_since) { 10.minutes.ago }
        let(:limit) { 10 }
        run_test!
      end
    end
  end
end