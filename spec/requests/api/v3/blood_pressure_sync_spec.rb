# frozen_string_literal: true

require "rails_helper"

RSpec.describe "BloodPressures sync", type: :request do
  let(:sync_route) { "/api/v3/blood_pressures/sync" }
  let(:request_user) { FactoryBot.create(:user) }
  let(:patient) { create(:patient, registration_facility: request_user.facility) }

  let(:model) { BloodPressure }

  let(:build_payload) { -> { build_blood_pressure_payload(FactoryBot.build(:blood_pressure, patient: patient, facility: request_user.facility)) } }
  let(:build_invalid_payload) { -> { build_invalid_blood_pressure_payload } }
  let(:update_payload) { ->(blood_pressure) { updated_blood_pressure_payload blood_pressure } }

  def to_response(blood_pressure)
    Api::V3::Transformer.to_response(blood_pressure)
  end

  include_examples "v3 API sync requests"
end
