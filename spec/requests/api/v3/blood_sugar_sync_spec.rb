# frozen_string_literal: true

require "rails_helper"

RSpec.describe "BloodSugars sync", type: :request do
  let(:sync_route) { "/api/v3/blood_sugars/sync" }
  let(:request_user) { FactoryBot.create(:user) }
  let(:patient) { create(:patient, registration_facility: request_user.facility) }

  let(:model) { BloodSugar }

  let(:build_payload) { -> { build_blood_sugar_payload(FactoryBot.build(:blood_sugar, patient: patient, facility: request_user.facility)) } }
  let(:build_invalid_payload) { -> { build_invalid_blood_sugar_payload } }
  let(:update_payload) { ->(blood_sugar) { updated_blood_sugar_payload blood_sugar } }

  def to_response(blood_sugar)
    Api::V3::BloodSugarTransformer.to_response(blood_sugar)
  end

  include_examples "v3 API sync requests"
end
