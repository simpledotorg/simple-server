require "rails_helper"

RSpec.describe Experimentation::TreatmentGroup, type: :model do
  describe "associations" do
    it { should belong_to(:experiment) }
    it { should have_many(:reminder_templates) }
    it { should have_many(:treatment_group_memberships) }
    it { should have_many(:patients).through(:treatment_group_memberships) }
  end

  describe "validations" do
    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:index) }
    it { should validate_numericality_of(:index) }

    it "does not allow indexes less than zero" do
      group = build(:treatment_group, index: -1)
      expect(group.valid?).to eq(false)
      group.index = 0
      expect(group.valid?).to eq(true)
    end
  end
end
