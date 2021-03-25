require "rails_helper"

RSpec.describe Experimentation::TreatmentCohort, type: :model do
  describe "associations" do
    it { should belong_to(:experiment) }
    it { should have_many(:reminder_templates) }
  end

  describe "validations" do
    it { should validate_presence_of(:cohort_identifier) }
  end
end
