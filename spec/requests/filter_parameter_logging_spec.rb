require 'rails_helper'

RSpec.describe 'Filter parameter logging spec', type: :request do
  let(:model) { Patient }
  let(:request_user) { FactoryBot.create(:user) }

  let(:sync_route) { '/api/v3/patients/sync' }

  let(:build_payload) { -> { build_patient_payload(FactoryBot.build(:patient, registration_facility: request_user.facility)) } }
  let(:build_invalid_payload) { -> { build_invalid_patient_payload } }
  let(:update_payload) { ->(record) { updated_patient_payload record } }

  def to_response(patient)
    Api::V3::PatientTransformer.to_nested_response(patient)
  end

  include_examples 'v3 API sync requests'

  fit 'pushes 3 new patients, updates only address or phone numbers, and pulls updated ones' do
    output = StringIO.new
    test_logger = Logger.new(output)
    allow(ActionController::Base).to receive(:logger).and_return(test_logger)

    first_patients_payload = (1..3).map { build_payload.call }
    post sync_route, params: { patients: first_patients_payload }.to_json, headers: headers
    get sync_route, params: {}, headers: headers
    process_token = JSON(response.body)['process_token']

    created_patients         = Patient.find(first_patients_payload.map { |patient| patient['id'] })
    updated_patients_payload = created_patients.map do |patient|
      updated_patient_payload(patient)
        .except(%w[address phone_numbers business_identifiers].sample)
    end

    post sync_route, params: { patients: updated_patients_payload }.to_json, headers: headers
    get sync_route, params: { process_token: process_token }, headers: headers

    assert_sync_success(response, process_token)

    puts output.string
    str = output.string
    first_patients_payload.each do |payload|
      payload.each do |attr, value|
        next if value.blank?
        unless attr =~ WHITELISTED_KEYS_MATCHER
          expect(str).to_not include(value.to_s), "expected to not have blacklisted #{attr.inspect} logged with value #{value.inspect}"
        end
      end
    end

  end

end
