require "rails_helper"

RSpec.describe Access, type: :model do
  describe "Validations" do
    it { is_expected.to validate_presence_of(:mode) }
  end

  describe "Associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:scope).optional }
  end

  context ".organizations" do
    let!(:admin) { create(:admin) }
    let!(:organization_1) { create(:organization) }
    let!(:organization_2) { create(:organization) }
    let!(:organization_3) { create(:organization) }
    let!(:manager_access) { create(:access, :manager, user: admin, scope: organization_1) }
    let!(:viewer_access) { create(:access, :viewer, user: admin, scope: organization_2) }

    context "view action" do
      it "returns all organizations the user has access to" do
        expect(admin.organizations(:view)).to include(organization_1, organization_2)
        expect(admin.organizations(:view)).not_to include(organization_3)
      end
    end

    context "manage action" do
      it "returns all organizations the user has admin access to" do
        expect(admin.accesses.admin.organizations).to include(organization_1)
        expect(admin.accesses.admin.organizations).not_to include(organization_2, organization_3)
      end
    end
  end

  context ".facility_groups" do
    let!(:admin) { create(:admin) }
    let!(:facility_group_1) { create(:facility_group) }
    let!(:facility_group_2) { create(:facility_group) }
    let!(:facility_group_3) { create(:facility_group) }
    let!(:access_1) { create(:access, user: admin, mode: :manager, scope: facility_group_1) }
    let!(:access_2) { create(:access, user: admin, mode: :viewer, scope: facility_group_2) }

    it "returns all facility_groups the user has access to" do
      expect(admin.accesses.facility_groups).to include(facility_group_1, facility_group_2)
      expect(admin.accesses.facility_groups).not_to include(facility_group_3)
    end

    it "returns all facility_groups the user has admin access to" do
      expect(admin.accesses.admin.facility_groups).to include(facility_group_1)
      expect(admin.accesses.admin.facility_groups).not_to include(facility_group_2, facility_group_3)
    end
  end

  context ".facilities" do
    let!(:admin) { create(:admin) }
    let!(:facility_1) { create(:facility) }
    let!(:facility_2) { create(:facility) }
    let!(:facility_3) { create(:facility) }
    let!(:access_1) { create(:access, user: admin, mode: :manager, scope: facility_1) }
    let!(:access_2) { create(:access, user: admin, mode: :viewer, scope: facility_2) }

    it "returns all facilities the user has access to" do
      expect(admin.accesses.facilities).to include(facility_1, facility_2)
      expect(admin.accesses.facilities).not_to include(facility_3)
    end

    it "returns all facilities the user has admin access to" do
      expect(admin.accesses.admin.facilities).to include(facility_1)
      expect(admin.accesses.admin.facilities).not_to include(facility_2, facility_3)
    end
  end
end
