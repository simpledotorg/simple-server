require "rails_helper"

RSpec.describe Api::V4::DrugTransformer do
  describe "to_response" do
    drug = Drug.first

    it "appends protocol: 'no'" do
      transformed_drug = Api::V4::DrugTransformer.to_response(drug)
      expect(transformed_drug["protocol"]).to eq("no")
    end

    it "appends common: 'yes'" do
      transformed_drug = Api::V4::DrugTransformer.to_response(drug)
      expect(transformed_drug["common"]).to eq("yes")
    end

    it "appends created_at, updated_at, and deleted_at timestamps" do
      transformed_drug = Api::V4::DrugTransformer.to_response(drug)
      expect(transformed_drug["created_at"]).to eq(Drug::CREATED_TIME)
      expect(transformed_drug["updated_at"]).to eq(Drug::UPDATED_TIME)
      expect(transformed_drug.keys).to include("deleted_at")
      expect(transformed_drug["deleted_at"]).to be_nil
    end

    it "sets deleted_at timestamp for deleted records" do
      drug[:deleted] = true
      transformed_drug = Api::V4::DrugTransformer.to_response(drug)
      expect(transformed_drug["deleted_at"]).to eq(Drug::UPDATED_TIME)
    end
  end
end
