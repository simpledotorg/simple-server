require "rails_helper"

RSpec.describe Access, type: :model do
  describe "Associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:resource).optional }
  end

  describe "validations" do
    it "validates roles" do
      is_expected.to validate_presence_of(:role)
      is_expected.to define_enum_for(:role)
        .with_values(super_admin: "super_admin", admin: "admin", analyst: "analyst")
        .backed_by_column_of_type(:string)
    end
  end

  describe "scope methods" do
    let!(:admin) { create(:admin) }
    context ".organizations" do
      let!(:organization_1) { create(:organization) }
      let!(:organization_2) { create(:organization) }
      let!(:organization_3) { create(:organization) }
      let!(:access_1) { create(:access, user: admin, role: :admin, resource: organization_1)}
      let!(:access_2) { create(:access, user: admin, role: :analyst, resource: organization_2)}

      it "returns all organizations the user has access to" do
        expect(admin.accesses.organizations).to include(organization_1, organization_2)
        expect(admin.accesses.organizations).not_to include(organization_3)
      end

      it "returns all organizations the user has admin access to" do
        expect(admin.accesses.admin.organizations).to include(organization_1)
        expect(admin.accesses.admin.organizations).not_to include(organization_2, organization_3)
      end
    end

    context ".facility_groups" do
      let!(:facility_group_1) { create(:facility_group) }
      let!(:facility_group_2) { create(:facility_group) }
      let!(:facility_group_3) { create(:facility_group) }
      let!(:access_1) { create(:access, user: admin, role: :admin, resource: facility_group_1)}
      let!(:access_2) { create(:access, user: admin, role: :analyst, resource: facility_group_2)}

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
      let!(:facility_1) { create(:facility) }
      let!(:facility_2) { create(:facility) }
      let!(:facility_3) { create(:facility) }
      let!(:access_1) { create(:access, user: admin, role: :admin, resource: facility_1)}
      let!(:access_2) { create(:access, user: admin, role: :analyst, resource: facility_2)}

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
end
