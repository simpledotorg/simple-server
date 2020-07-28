require "rails_helper"

RSpec.describe Access, type: :model do
  describe "Validations" do
    it { is_expected.to validate_presence_of(:mode) }
    it {
      is_expected.to define_enum_for(:mode)
        .with_values(super_admin: "super_admin", manager: "manager", viewer: "viewer")
        .backed_by_column_of_type(:string)
    }

    context "resource" do
      let!(:admin) { create(:admin) }
      let!(:resource) { create(:facility) }

      it "is invalid if user has more than one access per resource" do
        __valid_access = create(:access, :viewer, user: admin, resource: resource)
        invalid_access = build(:access, :manager, user: admin, resource: resource)

        expect(invalid_access).to_not be_valid
        expect(invalid_access.errors.messages[:user]).to eq ["can only have one access per resource."]
      end

      it "is invalid if non super-admins don't have a resource" do
        invalid_access = build(:access, :viewer, user: admin, resource: nil)

        expect(invalid_access).to_not be_valid
        expect(invalid_access.errors.messages[:resource]).to eq ["must exist", "is required if not a super_admin."]
      end

      it "is invalid if super_admin has a resource" do
        invalid_access = build(:access, :super_admin, user: admin, resource: create(:facility))

        expect(invalid_access).to_not be_valid
        expect(invalid_access.errors.messages[:resource]).to eq ["must be nil if super_admin"]
      end

      it "is invalid if resource_type is not in the allow list" do
        valid_access_1 = build(:access, :viewer, user: admin, resource: create(:organization))
        valid_access_2 = build(:access, :viewer, user: admin, resource: create(:facility_group))
        valid_access_3 = build(:access, :viewer, user: admin, resource: create(:facility))
        invalid_access = build(:access, :viewer, user: admin, resource: create(:appointment))

        expect(valid_access_1).to be_valid
        expect(valid_access_2).to be_valid
        expect(valid_access_3).to be_valid
        expect(invalid_access).to_not be_valid
        expect(invalid_access.errors.messages[:resource_type]).to eq ["is not included in the list"]
      end
    end
  end

  describe "Associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:resource) }
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
