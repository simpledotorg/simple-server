require "rails_helper"

RSpec.describe EstimatedPopulation, type: :model do
  describe "validations" do
    it "is not valid without a population" do
      region = Region.new
      estimated_population = EstimatedPopulation.new(diagnosis: "HTN", region_id: region.id)

      expect(estimated_population).to_not be_valid
    end

    it "is not valid without a diagnosis" do
      region = Region.new
      estimated_population = EstimatedPopulation.new(population: 1, region_id: region.id)

      expect(estimated_population).to_not be_valid
    end

    it "is not valid if diagnosis is not enum" do
      region = Region.new
      estimated_population = EstimatedPopulation.new

      # Valid diagnosis values
      estimated_population.diagnosis = "HTN"
      estimated_population.diagnosis = "DM"

      expect { estimated_population.diagnosis = "CANCER" }.to raise_error(ArgumentError)
    end

    it "is not valid if region_id is not passed" do
      region = Region.new
      estimated_population = EstimatedPopulation.new(population: 1, diagnosis: "HTN")

      expect(estimated_population).to_not be_valid
    end
  end
end