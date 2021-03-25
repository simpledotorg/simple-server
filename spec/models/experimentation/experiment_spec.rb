require "rails_helper"

RSpec.describe Experimentation::Experiment, type: :model do
  describe "associations" do
    it { should have_many(:treatment_cohorts) }
  end

  describe "validations" do
    it { should validate_presence_of(:state) }
  end
end
