require "rails_helper"

RSpec.describe Experimentation::TreatmentBucket, type: :model do
  describe "associations" do
    it { should belong_to(:experiment) }
    it { should have_many(:reminder_templates) }
  end

  describe "validations" do
    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:index) }
    it { should validate_numericality_of(:index) }

    it "does not allow indexes less than zero" do
      bucket = build(:treatment_bucket, index: -1)
      expect(bucket.valid?).to eq(false)
      bucket.index = 0
      expect(bucket.valid?).to eq(true)
    end
  end
end
