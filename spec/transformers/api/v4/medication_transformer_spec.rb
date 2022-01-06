# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V4::MedicationTransformer do
  describe "to_response" do
    medication = Medication.first

    it "appends protocol: 'no'" do
      transformed_medication = Api::V4::MedicationTransformer.to_response(medication)
      expect(transformed_medication["protocol"]).to eq("no")
    end

    it "appends common: 'yes'" do
      transformed_medication = Api::V4::MedicationTransformer.to_response(medication)
      expect(transformed_medication["common"]).to eq("yes")
    end

    it "appends created_at, updated_at, and deleted_at timestamps" do
      transformed_medication = Api::V4::MedicationTransformer.to_response(medication)
      expect(transformed_medication["created_at"]).to eq(Medication::CREATED_TIME)
      expect(transformed_medication["updated_at"]).to eq(Medication::UPDATED_TIME)
      expect(transformed_medication.keys).to include("deleted_at")
      expect(transformed_medication["deleted_at"]).to be_nil
    end

    it "sets deleted_at timestamp for deleted records" do
      medication[:deleted] = true
      transformed_medication = Api::V4::MedicationTransformer.to_response(medication)
      expect(transformed_medication["deleted_at"]).to eq(Medication::UPDATED_TIME)
    end
  end
end
