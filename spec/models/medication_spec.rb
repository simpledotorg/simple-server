# frozen_string_literal: true

require "rails_helper"

RSpec.describe Medication, type: :model do
  describe "timestamp methods" do
    medication = Medication.first

    describe "created_at" do
      it "returns the medications.yml file's creation time" do
        expect(medication.created_at).to eq(Medication::CREATED_TIME)
      end
    end

    describe "updated_at" do
      it "returns the medications.yml file's updated time" do
        expect(medication.created_at).to eq(Medication::UPDATED_TIME)
      end
    end

    describe "deleted_at" do
      it "returns nil for non-deleted medications" do
        medication[:deleted] = false
        expect(medication.deleted_at).to be_nil
      end

      it "returns the medications.yml file's updated time for deleted medications" do
        medication[:deleted] = true
        expect(medication.deleted_at).to eq(Medication::UPDATED_TIME)
      end
    end
  end
end
