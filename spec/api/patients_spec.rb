require 'swagger_helper'

describe 'Patients API' do

  path '/patients/sync' do

    post 'Syncs patient, address and phone number data from device to server.' do
      tags 'patient'
      consumes 'application/json'
      parameter name: :patients, in: :body, schema: patient_sync_request_spec

      response '200', 'patients created' do
        let(:patients) { { patients: (1..10).map { build_patient } } }
        run_test!
      end

      response '200', 'some, or no errors were found' do
        schema patient_sync_errors_spec
        let(:patients) { { patients: (1..10).map { build_invalid_patient } } }
        run_test!
      end
    end
  end
end