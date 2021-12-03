require "rails_helper"

RSpec.describe EstimatedPopulation, type: :model do
  describe "validations" do
    it "is not valid without a population" do
      region = Region.create(name: "New York", region_type: "state")
      estimated_population = EstimatedPopulation.new()
    end
  end
end