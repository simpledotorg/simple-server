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

    it "updates state population when district population is set/updated" do
      state = Region.create!(name: "State", region_type: "state", reparent_to: Region.root)
      district_1 = Region.create!(name: "District 1", region_type: "district", reparent_to: state)
      district_2 = Region.create!(name: "District 2", region_type: "district", reparent_to: state)

      expect(state.estimated_population).to be_nil
      district_1_population = district_1.create_estimated_population!(population: 1000, diagnosis: "HTN")
      expect(district_1.estimated_population).to eq(district_1_population)
      expect(state.reload_estimated_population.population).to eq(1000)

      district_1_population.population = 1500
      district_1_population.save!

      expect(district_1.estimated_population.population).to eq(1500)
      expect(state.reload_estimated_population.population).to eq(1500)

      district_2_population = district_2.create_estimated_population!(population: 1000, diagnosis: "HTN")
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
      expect(state.reload_estimated_population.population).to eq(district_1_population.population + district_2_population.population)

      EstimatedPopulation.find(district_1_population.id).destroy

      expect(district_1.reload_estimated_population).to be_nil
      expect(state.reload_estimated_population.population).to eq(district_2.estimated_population.population)
    end

    fit "creates an EstimatedPopulation when a facility group is created" do
      organization = Organization.create!(name: "Organization")
      facility_group = create(:facility_group, organization: organization)

      puts facility_group.region.inspect
    end
  end
end