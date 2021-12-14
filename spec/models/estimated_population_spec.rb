require "rails_helper"

RSpec.describe EstimatedPopulation, type: :model do
  describe "validations" do
    it "is valid without a population" do
      region = Region.create!(name: "State", region_type: "state", reparent_to: Region.root)
      estimated_population = EstimatedPopulation.new(diagnosis: "HTN", region_id: region.id)

      expect(estimated_population).to be_valid
      expect(estimated_population.population).to be_nil
    end

    it "is not valid without a diagnosis" do
      region = Region.create!(name: "State", region_type: "state", reparent_to: Region.root)
      estimated_population = EstimatedPopulation.new(population: 1, region_id: region.id, diagnosis: nil)

      expect(estimated_population).to_not be_valid
      expect(estimated_population.errors[:diagnosis]).to eq(["can't be blank"])
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
      expect(block_population).to_not be_valid
      expect(block_population.errors[:region]).to eq(["can only set population for a district or a state"])
      expect(facility_population).to_not be_valid
      expect(facility_population.errors[:region]).to eq(["can only set population for a district or a state"])
    end

    it "creates an EstimatedPopulation record when a population is set" do
      organization = Organization.create!(name: "Organization")
      facility_group = create(:facility_group, organization: organization, district_estimated_population: 2000)

      expect(facility_group.estimated_population).to be_present
      expect(facility_group.estimated_population.population).to eq(2000)
    end
  end

  describe "recalculate_state_population!" do
    it "updates state population to total of all districts" do
      state = Region.create!(name: "State", region_type: "state", reparent_to: Region.root)
      district_1 = Region.create!(name: "District 1", region_type: "district", reparent_to: state)
      district_2 = Region.create!(name: "District 2", region_type: "district", reparent_to: state)

      expect(state.estimated_population).to be_nil
      district_1_population = district_1.create_estimated_population!(population: 1000, diagnosis: "HTN")
      expect(district_1.estimated_population).to eq(district_1_population)

      state.recalculate_state_population!
      expect(state.reload_estimated_population.population).to eq(1000)

      district_1_population.population = 1500
      district_1_population.save!

      state.recalculate_state_population!
      expect(district_1.estimated_population.population).to eq(1500)
      expect(state.reload_estimated_population.population).to eq(1500)

      district_2.create_estimated_population!(population: 1000, diagnosis: "HTN")
      state.recalculate_state_population!
      expect(state.reload_estimated_population.population).to eq(2500)
    end

    it "updates state population when a district is deleted" do
      state = Region.create!(name: "State", region_type: "state", reparent_to: Region.root)
      district_1 = Region.create!(name: "District 1", region_type: "district", reparent_to: state)
      district_2 = Region.create!(name: "District 2", region_type: "district", reparent_to: state)

      district_1_population = EstimatedPopulation.create!(population: 1000, diagnosis: "HTN", region_id: district_1.id)
      district_2_population = EstimatedPopulation.create!(population: 1000, diagnosis: "HTN", region_id: district_2.id)

      expect(district_1.estimated_population.population).to eq(district_1_population.population)
      expect(district_2.estimated_population.population).to eq(district_2_population.population)
      state.recalculate_state_population!
      expect(state.reload_estimated_population.population).to eq(district_1_population.population + district_2_population.population)

      EstimatedPopulation.find(district_1_population.id).destroy
      state.recalculate_state_population!

      expect(district_1.reload_estimated_population).to be_nil
      expect(state.reload_estimated_population.population).to eq(district_2.estimated_population.population)
    end
  end

  describe "is_population_available_for_all_districts" do
    it "returns true when all districts have a population" do
      state = Region.create!(name: "State", region_type: "state", reparent_to: Region.root)
      district_1 = Region.create!(name: "District 1", region_type: "district", reparent_to: state)
      district_2 = Region.create!(name: "District 2", region_type: "district", reparent_to: state)

      district_1_population = EstimatedPopulation.create!(population: 1500, diagnosis: "HTN", region_id: district_1.id)
      district_2_population = EstimatedPopulation.create!(population: 1500, diagnosis: "HTN", region_id: district_2.id)
      state.recalculate_state_population!

      expect(district_1_population.is_population_available_for_all_districts).to eq(true)
      expect(district_2_population.is_population_available_for_all_districts).to eq(true)
      expect(state.estimated_population.is_population_available_for_all_districts).to eq(true)
    end

    it "returns false when not all districts have a population" do
      state = Region.create!(name: "State", region_type: "state", reparent_to: Region.root)
      district_1 = Region.create!(name: "District 1", region_type: "district", reparent_to: state)
      district_2 = Region.create!(name: "District 2", region_type: "district", reparent_to: state)

      district_2_population = EstimatedPopulation.create!(population: 1500, diagnosis: "HTN", region_id: district_2.id)
      state.recalculate_state_population!

      expect(district_1.estimated_population).to be_nil
      expect(district_2_population.is_population_available_for_all_districts).to eq(false)
      expect(state.estimated_population.is_population_available_for_all_districts).to eq(false)
    end
  end
end
