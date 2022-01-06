# frozen_string_literal: true

require "rails_helper"

RSpec.describe Protocol, type: :model do
  describe "Associations" do
    it { should have_many(:protocol_drugs) }
  end

  describe "Validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:follow_up_days) }
    it { should validate_numericality_of(:follow_up_days) }
  end

  describe "Behavior" do
    it_behaves_like "a record that is deletable"
  end

  describe "Attribute sanitization" do
    it "squishes and upcases the first letter of the name" do
      protocol = FactoryBot.create(:protocol, name: " protocol  name 1  ")
      expect(protocol.name).to eq("Protocol name 1")
    end
  end

  describe "#as_json" do
    it "includes protocol drugs sorted by name, and dosage" do
      protocol = FactoryBot.create(:protocol, :with_tracked_drugs)
      expect(protocol.as_json["protocol_drugs"]).not_to be_empty
      rxnorm_codes = protocol.as_json["protocol_drugs"].map { |protocol_drug| protocol_drug["rxnorm_code"] }
      expect(rxnorm_codes).to eq(%w[329528 329526 331132 316049 979467 316764 316765])
    end
  end
end
