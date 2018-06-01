require 'rails_helper'

RSpec.describe 'BloodPressures sync', type: :request do
  let(:sync_route) { '/api/v1/blood_pressures/sync' }
  let(:headers) { { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' } }

  let(:response_key) { 'blood_pressures' }
  let(:empty_payload) { { blood_pressures: [] } }
  let(:valid_payload) { { blood_pressures: [build_blood_pressure_payload] } }
  let(:model) { BloodPressure }
  let(:expected_response) do
    valid_payload[:blood_pressures].map do |blood_pressure|
      blood_pressure.with_int_timestamps.to_json_and_back
    end
  end

  let(:created_records) { (1..10).map { build_blood_pressure_payload } }
  let(:many_valid_records) { { blood_pressures: created_records } }
  let(:updated_records) do
    BloodPressure
      .find(created_records.map { |blood_pressure| blood_pressure['id'] })
      .take(5)
      .map { |record| updated_blood_pressure_payload record }
  end
  let(:updated_payload) { { blood_pressures: updated_records } }

  def to_response(blood_pressure)
    Api::V1::Transformer.to_response(blood_pressure)
  end

  include_examples 'sync requests'
end
