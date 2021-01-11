require "rails_helper"

describe DrugStock, type: :model do
  describe "Associations" do
    it { should belong_to(:user) }
    it { should belong_to(:facility) }
    it { should belong_to(:protocol_drug) }
  end

  describe "Validations" do
    it { should validate_presence_of(:in_stock) }
    it { should validate_presence_of(:received) }
    it { should validate_presence_of(:recorded_at) }
    it { should validate_numericality_of(:in_stock) }
    it { should validate_numericality_of(:received) }
  end

  describe "Behavior" do
    it_behaves_like "a record that is deletable"
  end
end
