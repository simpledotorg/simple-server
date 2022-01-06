# frozen_string_literal: true

require "rails_helper"

RSpec.describe Organization, type: :model do
  describe "Associations" do
    it { is_expected.to have_many(:facility_groups) }
    it { is_expected.to have_many(:facilities).through(:facility_groups) }
    it { is_expected.to have_many(:appointments).through(:facilities) }
    it { is_expected.to have_many(:users) }
    it { is_expected.to have_many(:protocols).through(:facility_groups) }

    it "deletes all dependent facility groups" do
      organization = FactoryBot.create(:organization)
      facility_groups = FactoryBot.create_list(:facility_group, 5, organization: organization)
      expect { organization.destroy }.to change { FacilityGroup.count }.by(-5)
      expect(FacilityGroup.where(id: facility_groups.map(&:id))).to be_empty
    end

    it "nullifies facility_group_id in facilities of the organization" do
      organization = FactoryBot.create(:organization)
      facility_groups = FactoryBot.create_list(:facility_group, 5, organization: organization)
      facility_groups.each { |facility_group| FactoryBot.create_list(:facility, 5, facility_group: facility_group) }
      expect { organization.destroy }.not_to change { Facility.count }
      expect(Facility.where(facility_group: facility_groups)).to be_empty
    end
  end

  describe "Validations" do
    it { should validate_presence_of(:name) }
  end

  describe "Behavior" do
    it_behaves_like "a record that is deletable"
  end

  describe "Callbacks" do
    context "after_create" do
      it "creates a region" do
        organization = create(:organization, name: "IHCI", description: "IHCI org")
        expect(organization.region).to be_present
        expect(organization.region).to be_persisted
        expect(organization.region.name).to eq "IHCI"
        expect(organization.region.description).to eq "IHCI org"
        expect(organization.region.path).to eq "india.ihci"
      end
    end

    context "after_update" do
      it "updates the associated region" do
        organization = create(:organization, name: "IHCI")
        organization.update(name: "New Org Name", description: "New Description")
        expect(organization.region.name).to eq "New Org Name"
        expect(organization.region.description).to eq "New Description"
        expect(organization.region.path).to eq "india.ihci"
      end

      it "does nothing if the org name / description hasn't changed" do
        organization = create(:organization, name: "IHCI")
        expect_any_instance_of(Region).to receive(:save!).never
        organization.touch
      end
    end
  end

  describe "Attribute sanitization" do
    it "squishes and upcases the first letter of the name" do
      org = FactoryBot.create(:organization, name: " org name  1  ")
      expect(org.name).to eq("Org name 1")
    end
  end

  describe ".discardable?" do
    let!(:organization) { create(:organization) }

    context "isn't discardable if data exists" do
      it "has users" do
        facility_group = create(:facility_group, organization: organization)
        facility = create(:facility, facility_group: facility_group)
        create(:user, registration_facility: facility)

        expect(organization.discardable?).to be false
      end

      it "has appointments" do
        facility_group = create(:facility_group, organization: organization)
        facility = create(:facility, facility_group: facility_group)
        create(:appointment, facility: facility)

        expect(organization.discardable?).to be false
      end

      it "has facility groups" do
        create(:facility_group, organization: organization)

        expect(organization.discardable?).to be false
      end
    end

    context "is discardable if no data exists" do
      it "has no data" do
        expect(organization.discardable?).to be true
      end
    end
  end
end
