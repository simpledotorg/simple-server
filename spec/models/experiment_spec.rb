require "rails_helper"

RSpec.describe Experiment, type: :model do

  subject(:experiment) { create(:experiment) }


  end

  describe "#bucket_size" do
    it "should return the number of buckets in the experiment" do
      expect(experiment.bucket_size).to eq(3)
    end
  end
end
