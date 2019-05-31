require 'rails_helper'

RSpec.describe 'BloodPressures sync', type: :request do
  let(:sync_route) { '/api/v2/blood_pressures/sync' }
  let(:request_user) { FactoryBot.create(:user) }

  let(:model) { BloodPressure }

  let(:build_payload) { lambda { build_blood_pressure_payload_v2(FactoryBot.build(:blood_pressure, facility: request_user.facility)) } }
  let(:build_invalid_payload) { lambda { build_invalid_blood_pressure_payload } }
  let(:update_payload) { lambda { |blood_pressure| updated_blood_pressure_payload blood_pressure } }

  def to_response(blood_pressure)
    Api::V2::BloodPressureTransformer.to_response(blood_pressure)
  end

  include_examples 'v2 API sync requests'
end
