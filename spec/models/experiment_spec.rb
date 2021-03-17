require "rails_helper"

RSpec.describe Experiment, type: :model do
  subject(:experiment) { Experiment.first }

  describe "#variations" do
    it "should contain a hash from the yaml file" do
      expected_response = {
        "A"=>[{"message"=>"Hi there", "when"=>-3},
              {"message"=>"Are you coming?", "when"=>0},
              {"message"=>"You are very late", "when" => 3}],
        "B"=>[{"message"=>"Hi there. Come soon.", "when"=>-3}],
        "C"=>[{"message"=>"You are late", "when"=>3}]
      }
      expect(experiment.variations).to eq(expected_response)
    end
  end

  describe "bucket_size" do
    it "should return the number of buckets in the experiment" do
      expect(experiment.bucket_size).to eq(3)
    end
  end
end