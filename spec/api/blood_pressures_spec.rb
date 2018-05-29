require 'swagger_helper'

describe 'BloodPressures API' do

  path '/blood_pressures/sync' do

    post 'Syncs blood pressure data from device to server.' do
      tags 'Blood Pressure'
      parameter name: :blood_pressures, in: :body, schema: Api::V1::Spec.blood_pressure_sync_from_user_request_spec

      response '200', 'blood pressures created' do
        let(:blood_pressures) { { blood_pressures: (1..10).map { build_blood_pressure_payload } } }
        run_test!
      end

      response '200', 'some, or no errors were found' do
        schema Api::V1::Spec.sync_from_user_errors_spec
        let(:blood_pressures) { { blood_pressures: (1..10).map { build_invalid_blood_pressure_payload } } }
        run_test!
      end
    end
  end
end