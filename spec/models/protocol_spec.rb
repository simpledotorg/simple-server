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
end
