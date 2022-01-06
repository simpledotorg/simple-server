# frozen_string_literal: true

require "rails_helper"

RSpec.describe "PrescriptionDrugs sync", type: :request do
  let(:sync_route) { "/api/v3/prescription_drugs/sync" }
  let(:request_user) { FactoryBot.create(:user) }
  let(:patient) { create(:patient, registration_facility: request_user.facility) }

  let(:model) { PrescriptionDrug }

  let(:build_payload) { -> { build_prescription_drug_payload(FactoryBot.build(:prescription_drug, patient: patient, facility: request_user.facility)) } }
  let(:build_invalid_payload) { -> { build_invalid_prescription_drug_payload } }
  let(:update_payload) { ->(prescription_drug) { updated_prescription_drug_payload prescription_drug } }
  let(:keys_not_expected_in_response) { ["user_id"] }

  def to_response(prescription_drug)
    Api::V3::Transformer.to_response(prescription_drug).except("user_id")
  end

  include_examples "v3 API sync requests"
end
