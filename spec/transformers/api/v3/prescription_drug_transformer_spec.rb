# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V3::PrescriptionDrugTransformer do
  describe "to_response" do
    let(:prescription_drug) { FactoryBot.build(:prescription_drug) }

    it "removes user_id from prescription_drug response hashes" do
      transformed_prescription_drug = Api::V3::PrescriptionDrugTransformer.to_response(prescription_drug)
      expect(transformed_prescription_drug).not_to include("user_id")
    end
  end
end
