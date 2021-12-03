require "rails_helper"

RSpec.describe EstimatedPopulation, type: :model do
  describe "validations" do
    it "is not valid without a population" do
      region = Region.create!(name: "State", region_type: "state", reparent_to: Region.root)
      estimated_population = EstimatedPopulation.new(diagnosis: "HTN", region_id: region.id)

      expect(estimated_population).to_not be_valid
    end

    it "is not valid without a diagnosis" do
      region = Region.create!(name: "State", region_type: "state", reparent_to: Region.root)
      estimated_population = EstimatedPopulation.new(population: 1, region_id: region.id, diagnosis: nil)

      expect(estimated_population).to_not be_valid
    end

    it "is not valid if diagnosis is not enum" do
      region = Region.create!(name: "State", region_type: "state", reparent_to: Region.root)
      estimated_population = EstimatedPopulation.new(population: 1, region_id: region.id)

      # Valid diagnosis values
      estimated_population.diagnosis = "HTN"
      estimated_population.diagnosis = "DM"

      expect { estimated_population.diagnosis = "CANCER" }.to raise_error(ArgumentError)
    end

    it "can only be set for district or state" do
      state_region = Region.create!(name: "State", region_type: "state", reparent_to: Region.root)
      district_region = Region.create!(name: "District", region_type: "district", reparent_to: state_region)
      block_region = Region.create!(name: "Block", region_type: "block", reparent_to: district_region)
      facility_region = Region.create!(name: "Facility", region_type: "facility", reparent_to: block_region)

      state_population = EstimatedPopulation.new(population: 1, diagnosis: "HTN", region_id: state_region.id)
      district_population = EstimatedPopulation.new(population: 2, diagnosis: "DM", region_id: district_region.id)
      block_population = EstimatedPopulation.new(population: 3, diagnosis: "HTN", region_id: block_region.id)
      facility_population = EstimatedPopulation.new(population: 4, diagnosis: "DM", region_id: facility_region.id)

      expect(state_population).to be_valid
      expect(district_population).to be_valid
      expect(block_population).not_to be_valid
      expect(facility_population).not_to be_valid
    end

    fit "sums all district populations for state" do
      state_region = Region.create!(name: "State", region_type: "state", reparent_to: Region.root)
      district_region_1 = Region.create!(name: "District 1", region_type: "district", reparent_to: state_region)
      district_region_2 = Region.create!(name: "District 2", region_type: "district", reparent_to: state_region)
      district_region_3 = Region.create!(name: "District 3", region_type: "district", reparent_to: state_region)

      district_population_1 = EstimatedPopulation.new(population: 1000, diagnosis: "HTN", region_id: district_region_1.id)

      # NEXT: Finish writing test to sum district populations for state
    end
  end
end