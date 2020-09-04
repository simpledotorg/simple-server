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
    it { have_many(:medical_histories).through(:patients) }
    it { have_many(:communications).through(:appointments) }

    it { belong_to(:protocol) }

    it "nullifies facility_group_id in facilities" do
      facility_group = FactoryBot.create(:facility_group)
      FactoryBot.create_list(:facility, 5, facility_group: facility_group)
      expect { facility_group.destroy }.not_to change { Facility.count }
      expect(Facility.where(facility_group: facility_group)).to be_empty
    end
  end

  describe "Validations" do
    it { should validate_presence_of(:name) }
  end

  describe "Behavior" do
    it_behaves_like "a record that is deletable"
  end

  describe "Attribute sanitization" do
    it "squishes and upcases the first letter of the name" do
      facility_group = FactoryBot.create(:facility_group, name: "facility  Group  ")
      expect(facility_group.name).to eq("Facility Group")
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
end
