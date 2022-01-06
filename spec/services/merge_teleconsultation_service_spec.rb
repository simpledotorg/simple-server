# frozen_string_literal: true

require "rails_helper"

RSpec.describe MergeTeleconsultationService, type: :model do
  let!(:user) { create(:user) }

  context "when a request is being added" do
    it "sets the requested_medical_officer_id to the teleconsult medical officer id" do
      teleconsultation = build_teleconsultation_payload
      teleconsultation["record"] = nil
      transformed_params = Api::V4::TeleconsultationTransformer.from_request(teleconsultation)

      described_class.merge(transformed_params, user)

      db_teleconsultation = Teleconsultation.find(teleconsultation["id"])
      expect(db_teleconsultation.requested_medical_officer_id).to eq db_teleconsultation.medical_officer_id
    end

    it "shouldn't override the medical_officer_id if it is already set" do
      saved_teleconsultation = create(:teleconsultation)
      teleconsultation = updated_teleconsultation_payload(saved_teleconsultation)
        .merge("medical_officer_id" => create(:user).id)
      teleconsultation["record"] = nil
      transformed_params = Api::V4::TeleconsultationTransformer.from_request(teleconsultation)

      described_class.merge(transformed_params, user)

      db_teleconsultation = Teleconsultation.find(teleconsultation["id"])
      expect(db_teleconsultation.medical_officer_id).to eq saved_teleconsultation.medical_officer_id
    end
  end

  context "when a record is being added" do
    it "sets the medical_officer_id to the request user id" do
      teleconsultation = build_teleconsultation_payload
      teleconsultation["request"] = nil
      transformed_params = Api::V4::TeleconsultationTransformer.from_request(teleconsultation)

      described_class.merge(transformed_params, user)

      expect(Teleconsultation.find(transformed_params["id"]).medical_officer_id).to eq user.id
    end
  end
end
