# frozen_string_literal: true

require "rails_helper"

RSpec.describe FacilityGroup, type: :model do
  describe "Associations" do
    it { should belong_to(:organization) }
    it { should have_many(:facilities) }

    it { have_many(:patients).through(:facilities) }
    it { have_many(:assigned_patients).through(:facilities).source(:assigned_patients) }
    it { have_many(:blood_pressures).through(:facilities) }
    it { have_many(:blood_sugars).through(:facilities) }
    it { have_many(:prescription_drugs).through(:facilities) }
    it { have_many(:appointments).through(:facilities) }
    it { have_many(:teleconsultations).through(:facilities) }
    it { have_many(:medical_histories).through(:patients) }
    it { have_many(:communications).through(:appointments) }

    it { belong_to(:protocol) }

    it "nullifies facility_group_id in facilities" do
      facility_group = create(:facility_group)
      create_list(:facility, 5, facility_group: facility_group)

      expect { facility_group.destroy }.not_to change { Facility.count }
      expect(Facility.where(facility_group: facility_group)).to be_empty
    end
  end

  context "Validations" do
    it { should validate_presence_of(:name) }
  end

  context "Behavior" do
    it_behaves_like "a record that is deletable"
  end

  context "slugs" do
    it "generates slug on creation and avoids conflicts via appending a UUID" do
      facility_group_1 = create(:facility_group, name: "New York")

      expect(facility_group_1.slug).to eq("new-york")

      facility_group_2 = create(:facility_group, name: "New York")

      uuid_regex = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/
      expect(facility_group_2.slug).to match(/^new-york-#{uuid_regex}$/)
    end

    it "does not change the slug when renamed" do
      facility_group = create(:facility_group, name: "old_name")

      original_slug = facility_group.slug
      facility_group.name = "new name"
      facility_group.valid?
      facility_group.save!

      expect(facility_group.slug).to eq(original_slug)
    end
  end

  describe "Attribute sanitization" do
    it "squishes and upcases the first letter of the name" do
      facility_group = create(:facility_group, name: "facility  Group  ")
      expect(facility_group.name).to eq("Facility Group")
    end
  end

  describe "#create_state_region!" do
    it "creates a new state region if it doesn't exist" do
      org = create(:organization, name: "IHCI")
      facility_group = build(:facility_group, name: "FG", state: "Punjab", organization: org)
      facility_group.create_state_region!

      expect(Region.state_regions.pluck(:name)).to match_array ["Punjab"]
      expect(Region.state_regions.pluck(:path)).to contain_exactly("india.ihci.punjab")
    end

    it "does nothing if the state region already exists" do
      org = create(:organization, name: "IHCI")
      state_region = create(:region, :state, name: "Punjab", reparent_to: org.region)
      facility_group = build(:facility_group, name: "FG", state: state_region.name, organization: org)
      facility_group.create_state_region!

      expect(Region.state_regions.pluck(:name)).to match_array ["Punjab"]
      expect(Region.state_regions.pluck(:path)).to contain_exactly("india.ihci.punjab")
    end
  end

  describe "keeps block regions in sync" do
    it "creates blocks from new_block_names" do
      facility_group = create(:facility_group, name: "FG", state: "Punjab")

      facility_group.new_block_names = ["Block 1", "Block 1", "Block 2"]
      facility_group.sync_block_regions

      expect(facility_group.region.block_regions.map(&:name)).to contain_exactly("Block 1", "Block 2")
    end

    it "deletes blocks from remove_block_ids" do
      facility_group = create(:facility_group, name: "FG", state: "Punjab")
      district_region = facility_group.region
      district_region.block_regions.create!(name: "Block 1", reparent_to: district_region)
      district_region.block_regions.create!(name: "Block 2", reparent_to: district_region)

      block = district_region.block_regions.find_by!(name: "Block 1")
      facility_group.remove_block_ids = [block.id]

      facility_group.sync_block_regions

      expect(facility_group.region.block_regions.map(&:name)).to contain_exactly("Block 2")
    end
  end

  describe "#toggle_diabetes_management" do
    let!(:facility_group) { create(:facility_group) }
    let!(:facilities) { create_list(:facility, 2, facility_group: facility_group) }
    before { facility_group.reload }

    context "when enable_diabetes_management is set to true" do
      before { facility_group.enable_diabetes_management = true }

      it "enables diabetes management for all facilities" do
        facility_group.facilities.update(enable_diabetes_management: false)
        facility_group.toggle_diabetes_management
        expect(Facility.pluck(:enable_diabetes_management)).to all be true
      end
    end

    context "when enable_diabetes_management is set to false" do
      before { facility_group.enable_diabetes_management = false }

      it "disables diabetes management for all facilities if it is enabled for all facilities" do
        facility_group.facilities.update(enable_diabetes_management: true)
        facility_group.toggle_diabetes_management
        expect(Facility.pluck(:enable_diabetes_management)).to all be false
      end

      it "does not disable diabetes management for all facilities if it is enabled for some facilities" do
        facilities.first.update(enable_diabetes_management: true)
        facilities.second.update(enable_diabetes_management: false)
        facility_group.toggle_diabetes_management

        expect(Facility.pluck(:enable_diabetes_management)).to match_array [true, false]
      end
    end
  end

  describe ".discardable?" do
    let!(:org) { create(:organization, name: "IHCI") }
    let!(:facility_group) { create(:facility_group, organization: org) }

    context "isn't discardable if data exists" do
      it "has patients" do
        facility = create(:facility, facility_group: facility_group)
        create(:patient, registration_facility: facility)

        expect(facility_group.discardable?).to be false
      end

      it "has appointments" do
        facility = create(:facility, facility_group: facility_group)
        create(:appointment, facility: facility)

        expect(facility_group.discardable?).to be false
      end

      it "has facilities" do
        create(:facility, facility_group: facility_group)

        expect(facility_group.discardable?).to be false
      end

      it "has blood pressures" do
        facility = create(:facility, facility_group: facility_group)
        blood_pressure = create(:blood_pressure, facility: facility)
        create(:encounter, :with_observables, observable: blood_pressure)

        expect(facility_group.discardable?).to be false
      end

      it "has blood sugars" do
        facility = create(:facility, facility_group: facility_group)
        blood_sugar = create(:blood_sugar, facility: facility)
        create(:encounter, :with_observables, observable: blood_sugar)

        expect(facility_group.discardable?).to be false
      end
    end

    context "is discardable if no data exists" do
      it "has no data" do
        expect(facility_group.discardable?).to be true
      end
    end

    it "can be discarded" do
      facility_group.discard
      expect(facility_group).to be_discarded
    end

    it "can be discarded and updates state population after discard" do
      facility_group = create(:facility_group, name: "district-with-population", organization: org, district_estimated_population: 300)
      state = facility_group.region.state_region
      expect(state.estimated_population.population).to eq(300)
      facility_group.discard
      state.recalculate_state_population!
      expect(facility_group).to be_discarded
      expect(state.reload_estimated_population.population).to eq(0)
    end
  end

  describe "Callbacks" do
    context "after_create" do
      let!(:org) { create(:organization, name: "IHCI") }
      let!(:facility_group) { create(:facility_group, name: "FG", state: "Punjab", organization: org) }

      it "creates a region" do
        expect(facility_group.region).to be_present
        expect(facility_group.region).to be_persisted
        expect(facility_group.region.name).to eq "FG"
        expect(facility_group.region.path).to eq "india.ihci.punjab.fg"
      end

      it "creates the state region if it doesn't exist" do
        expect(facility_group.region.state_region.name).to eq "Punjab"
      end

      it "sets district estimed population if one is provided" do
        facility_group = create(:facility_group, name: "FG", state: "Punjab", organization: org, district_estimated_population: 2500)
        expect(facility_group.region).to be_present
        expect(facility_group.region).to be_persisted
        expect(facility_group.region.estimated_population).to be_present
        expect(facility_group.region.estimated_population.population).to eq(2500)
      end
    end

    context "after_update" do
      let!(:org) { create(:organization, name: "IHCI") }
      let!(:facility_group) { create(:facility_group, name: "FG", state: "Punjab", organization: org) }

      it "updates the associated region" do
        facility_group.update(name: "New FG name")
        expect(facility_group.region.name).to eq "New FG name"
        expect(facility_group.region.path).to eq "india.ihci.punjab.fg"
      end

      it "updates the state region" do
        new_state = create(:region, :state, name: "Maharashtra", reparent_to: org.region)
        facility_group.update(state: new_state.name)
        expect(facility_group.region.state_region.name).to eq "Maharashtra"
        expect(facility_group.region.path).to eq "india.ihci.maharashtra.fg"
      end

      it "updates district estimated population if one is provided" do
        expect {
          facility_group.update!(district_estimated_population: 1000)
        }.to change(EstimatedPopulation, :count).by(2)
        expect(facility_group.region.estimated_population).to be_present
        expect(facility_group.region.estimated_population.population).to eq(1000)
        expect {
          facility_group.update!(district_estimated_population: 3333)
        }.to change(EstimatedPopulation, :count).by(0)
        expect(facility_group.region.estimated_population.population).to eq(3333)
      end

      it "updates state estimated population if a district population is updated" do
        facility_group.update!(district_estimated_population: 1000)
        expect(facility_group.state_region.estimated_population.population).to be(1000)
        facility_group.update!(district_estimated_population: 5000)
        expect(facility_group.state_region.estimated_population.population).to be(5000)
      end
    end
  end
end
