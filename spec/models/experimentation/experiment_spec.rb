require "rails_helper"

RSpec.describe Experimentation::Experiment, type: :model do
  let(:experiment) { create(:experiment) }

  describe "associations" do
    it { should have_many(:treatment_buckets) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { experiment.should validate_uniqueness_of(:name) }
    it { should validate_presence_of(:state) }
    it { should validate_presence_of(:experiment_type) }
  end
end
