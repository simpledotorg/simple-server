require "rails_helper"

RSpec.describe Experimentation::TreatmentGroupMembership, type: :model do
  describe "associations" do
    it { should belong_to(:treatment_group) }
    it { should belong_to(:patient) }
  end
end
