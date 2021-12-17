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

  describe "hypertension_patient_coverage" do
    it "returns a percentage value when a region's population is > 0" do
      organization = create(:organization)
      facility_group_1 = create(:facility_group, name: "Brooklyn", organization: organization)
      facility_group_2 = create(:facility_group, name: "Manhattan", organization: organization)
      facility_1 = create(:facility, facility_group: facility_group_1)
      facility_2 = create(:facility, facility_group: facility_group_2)

      facility_group_1_population = EstimatedPopulation.create!(population: 100, diagnosis: "HTN", region_id: facility_group_1.region.id)
      facility_group_2_population = EstimatedPopulation.create!(population: 60, diagnosis: "HTN", region_id: facility_group_2.region.id)

      user = create(:admin, :manager, :with_access, resource: organization, organization: organization)

      create_list(:patient, 15, :hypertension, registration_facility: facility_1, registration_user: user)
      create_list(:patient, 5, :diabetes, registration_facility: facility_1, registration_user: user)
      create_list(:patient, 30, :hypertension, registration_facility: facility_2, registration_user: user)
      create_list(:patient, 3, :diabetes, registration_facility: facility_2, registration_user: user)

      expect(facility_group_1.region.estimated_population.hypertension_patient_coverage_rate).to eq(15.0)
      expect(facility_group_2.region.estimated_population.hypertension_patient_coverage_rate).to eq(50.0)
    end

    it "returns 100.0 when a region's hypertensive registered patients is > the region's estimated population" do
      organization = create(:organization)
      facility_group_1 = create(:facility_group, name: "Brooklyn", organization: organization)
      facility_group_2 = create(:facility_group, name: "Manhattan", organization: organization)
      facility_1 = create(:facility, facility_group: facility_group_1)
      facility_2 = create(:facility, facility_group: facility_group_2)

      facility_group_1_population = EstimatedPopulation.create!(population: 10, diagnosis: "HTN", region_id: facility_group_1.region.id)
      facility_group_2_population = EstimatedPopulation.create!(population: 25, diagnosis: "HTN", region_id: facility_group_2.region.id)

      user = create(:admin, :manager, :with_access, resource: organization, organization: organization)

      create_list(:patient, 15, :hypertension, registration_facility: facility_1, registration_user: user)
      create_list(:patient, 5, :diabetes, registration_facility: facility_1, registration_user: user)
      create_list(:patient, 30, :hypertension, registration_facility: facility_2, registration_user: user)
      create_list(:patient, 3, :diabetes, registration_facility: facility_2, registration_user: user)

      expect(facility_group_1.region.estimated_population.hypertension_patient_coverage_rate).to eq(100.0)
      expect(facility_group_2.region.estimated_population.hypertension_patient_coverage_rate).to eq(100.0)
    end

    it "returns nil if a district doesn't have registered patients" do
      organization = create(:organization)
      facility_group = create(:facility_group, name: "Brooklyn", organization: organization)

      facility_group_population = EstimatedPopulation.create!(population: 100, diagnosis: "HTN", region_id: facility_group.region.id)

      expect(facility_group.region.estimated_population.hypertension_patient_coverage_rate).to be_nil
    end

    it "returns nil if a district's hypertensive population is 0" do
      organization = create(:organization)
      facility_group = create(:facility_group, name: "Brooklyn", organization: organization)
      facility = create(:facility, facility_group: facility_group)

      facility_group_population = EstimatedPopulation.create!(population: 0, diagnosis: "HTN", region_id: facility_group.region.id)

      user = create(:admin, :manager, :with_access, resource: organization, organization: organization)

      create_list(:patient, 15, :hypertension, registration_facility: facility, registration_user: user)
      create_list(:patient, 5, :diabetes, registration_facility: facility, registration_user: user)
      
      expect(facility_group.region.estimated_population.hypertension_patient_coverage_rate).to be_nil
    end
  end

  describe "show_coverage" do
    it "returns true if a district has a hypertension patient coverage rate" do
      organization = create(:organization)
      facility_group = create(:facility_group, name: "Brooklyn", organization: organization)
      facility = create(:facility, facility_group: facility_group)

      facility_group_population = EstimatedPopulation.create!(population: 100, diagnosis: "HTN", region_id: facility_group.region.id)

      user = create(:admin, :manager, :with_access, resource: organization, organization: organization)

      create_list(:patient, 15, :hypertension, registration_facility: facility, registration_user: user)
      create_list(:patient, 5, :diabetes, registration_facility: facility, registration_user: user)

      expect(facility_group.region.estimated_population.show_coverage).to eq(true)
    end

    it "returns true if a state has populations for all child districts" do
      state = Region.create!(name: "State", region_type: "state", reparent_to: Region.root)
      district_1 = Region.create!(name: "District 1", region_type: "district", reparent_to: state)
      district_2 = Region.create!(name: "District 2", region_type: "district", reparent_to: state)

      district_1_population = EstimatedPopulation.create!(population: 1500, diagnosis: "HTN", region_id: district_1.id)
      district_2_population = EstimatedPopulation.create!(population: 1500, diagnosis: "HTN", region_id: district_2.id)
      state.recalculate_state_population!

      expect(district_1_population.is_population_available_for_all_districts).to eq(true)
      expect(district_2_population.is_population_available_for_all_districts).to eq(true)
      expect(state.estimated_population.show_coverage).to eq(true)
    end

    it "returns false if a district doesn't have a hypertension patient coverage rate" do
      organization = create(:organization)
      state = Region.create!(name: "State", region_type: "state", reparent_to: Region.root)
      district = Region.create!(name: "District", region_type: "district", reparent_to: state)

      district_population = EstimatedPopulation.create!(population: 100, diagnosis: "HTN", region_id: district.id)

      expect(district.estimated_population.show_coverage).to eq(false)
    end

    it "returns false if a state does not have all child district populations" do
      state = Region.create!(name: "State", region_type: "state", reparent_to: Region.root)
      district_1 = Region.create!(name: "District 1", region_type: "district", reparent_to: state)
      district_2 = Region.create!(name: "District 2", region_type: "district", reparent_to: state)

      district_1_population = EstimatedPopulation.create!(population: 1500, diagnosis: "HTN", region_id: district_1.id)
      state.recalculate_state_population!

      expect(district_1_population.is_population_available_for_all_districts).to eq(false)
      expect(state.estimated_population.show_coverage).to eq(false)
    end
  end
end
