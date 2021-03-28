require "rails_helper"

RSpec.describe Experimentation::TreatmentCohort, type: :model do
  describe "associations" do
    it { should belong_to(:experiment) }
    it { should have_many(:reminder_templates) }
  end

  describe "validations" do
    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:bucketing_index) }
    it { should validate_numericality_of(:bucketing_index) }

    it "does not allow bucketing indexes less than zero" do
      cohort = build(:treatment_cohort, bucketing_index: -1)
      expect(cohort.valid?).to eq(false)
      cohort.bucketing_index = 0
      expect(cohort.valid?).to eq(true)
    end
  end
end
