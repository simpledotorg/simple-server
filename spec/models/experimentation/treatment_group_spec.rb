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

    it "does not allow indexes less than zero" do
      group = build(:treatment_group, index: -1)
      expect(group.valid?).to eq(false)
      group.index = 0
      expect(group.valid?).to eq(true)
    end

    it "only allows creation treatment groups within an experiment with consecutive indexes starting at zero" do
      experiment = create(:experiment)
      expect(experiment.treatment_groups.create(description: "control", index: 1).valid?).to be_falsey
      expect(experiment.treatment_groups.create(description: "control", index: 0).valid?).to be_truthy
      expect(experiment.treatment_groups.create(description: "A", index: 2).valid?).to be_falsey
      expect(experiment.treatment_groups.create(description: "A", index: 1).valid?).to be_truthy
    end

    it "only allows creation of treatment groups with descriptions that are unique within the experiment" do
      experiment = create(:experiment)
      experiment.treatment_groups.create(description: "control", index: 0)
      expect(experiment.treatment_groups.create(description: "control", index: 1).valid?).to be_falsey
      expect(experiment.treatment_groups.create(description: "out of control", index: 1).valid?).to be_truthy
    end
  end
end
