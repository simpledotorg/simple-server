require "rails_helper"

RSpec.describe Drug, type: :model do
  describe "timestamp methods" do
    drug = Drug.first

    describe "created_at" do
      it "returns the drugs.yml file's creation time" do
        expect(drug.created_at).to eq(Drug::CREATED_TIME)
      end
    end

    describe "updated_at" do
      it "returns the drugs.yml file's updated time" do
        expect(drug.created_at).to eq(Drug::UPDATED_TIME)
      end
    end

    describe "deleted_at" do
      it "returns nil for non-deleted drugs" do
        drug[:deleted] = false
        expect(drug.deleted_at).to be_nil
      end

      it "returns the drugs.yml file's updated time for deleted drugs" do
        drug[:deleted] = true
        expect(drug.deleted_at).to eq(Drug::UPDATED_TIME)
      end
    end
  end
end
