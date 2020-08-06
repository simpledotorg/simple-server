require "rails_helper"

RSpec.describe Access, type: :model do
  describe "Validations" do
    it { is_expected.to validate_presence_of(:role) }

    it {
      is_expected.to define_enum_for(:role)
                       .with_values(super_admin: "super_admin", manager: "manager", viewer: "viewer")
                       .backed_by_column_of_type(:string)
    }

    context "resource" do
      let(:admin) { create(:admin) }
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

      it "is invalid if resource_type is not in the allow-list" do
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

  describe ".organizations" do
    let(:admin) { create(:admin) }
    let!(:organization_1) { create(:organization) }
    let!(:organization_2) { create(:organization) }
    let!(:organization_3) { create(:organization) }
    let!(:manager_access) { create(:access, :manager, user: admin, resource: organization_1) }
    let!(:viewer_access) { create(:access, :viewer, user: admin, resource: organization_2) }

    context "view action" do
      it "returns all organizations the user can view" do
        expect(admin.accesses.organizations(:view)).to contain_exactly(organization_1, organization_2)
        expect(admin.accesses.organizations(:view)).not_to contain_exactly(organization_3)
      end
    end

    context "manage action" do
      it "returns all organizations the user can manage" do
        expect(admin.accesses.organizations(:manage)).to contain_exactly(organization_1)
        expect(admin.accesses.organizations(:manage)).not_to contain_exactly(organization_2, organization_3)
      end
    end
  end

  pending ".facility_groups" do
    let(:admin) { create(:admin) }
    let!(:facility_group_1) { create(:facility_group) }
    let!(:facility_group_2) { create(:facility_group) }
    let!(:facility_group_3) { create(:facility_group) }
    let!(:access_1) { create(:access, user: admin, mode: :manager, resource: facility_group_1) }
    let!(:access_2) { create(:access, user: admin, mode: :viewer, resource: facility_group_2) }

    it "returns all facility_groups the user has access to" do
      expect(admin.accesses.facility_groups).to contain_exactly(facility_group_1, facility_group_2)
      expect(admin.accesses.facility_groups).not_to contain_exactly(facility_group_3)
    end

    it "returns all facility_groups the user has admin access to" do
      expect(admin.accesses.admin.facility_groups).to contain_exactly(facility_group_1)
      expect(admin.accesses.admin.facility_groups).not_to contain_exactly(facility_group_2, facility_group_3)
    end
  end

  describe ".facilities" do
    let(:viewer) { create(:admin) }
    let(:manager) { create(:admin) }

    context "for a direct facility-level access" do
      let!(:facility_1) { create(:facility) }
      let!(:facility_2) { create(:facility) }
      let!(:facility_3) { create(:facility) }
      let!(:manager_access) { create(:access, :manager, user: manager, resource: facility_1) }
      let!(:viewer_access) { create(:access, :viewer, user: viewer, resource: facility_2) }

      context "view action" do
        it "returns all facilities the manager can view" do
          expect(manager.accesses.facilities(:view)).to contain_exactly(facility_1)
          expect(manager.accesses.facilities(:view)).not_to contain_exactly(facility_2, facility_3)
        end

        it "returns all facilities the viewer can view" do
          expect(viewer.accesses.facilities(:view)).to contain_exactly(facility_2)
          expect(viewer.accesses.facilities(:view)).not_to contain_exactly(facility_1, facility_3)
        end
      end

      context "manage action" do
        it "returns all facilities the manager can manage" do
          expect(manager.accesses.facilities(:manage)).to contain_exactly(facility_1)
          expect(manager.accesses.facilities(:manage)).not_to contain_exactly(facility_2, facility_3)
        end

        it "returns all facilities the viewer can manage" do
          expect(viewer.accesses.facilities(:manage)).to be_empty
        end
      end
    end

    context "for a direct facility-group-level access" do
      let!(:facility_group_1) { create(:facility_group) }
      let!(:facility_group_2) { create(:facility_group) }
      let!(:facility_group_3) { create(:facility_group) }

      let!(:facility_1) { create(:facility, facility_group: facility_group_1) }
      let!(:facility_2) { create(:facility, facility_group: facility_group_2) }
      let!(:facility_3) { create(:facility, facility_group: facility_group_3) }
      let!(:facility_4) { create(:facility) }
      let!(:facility_5) { create(:facility) }
      let!(:facility_6) { create(:facility) }

      let!(:manager_access) { create(:access, :manager, user: manager, resource: facility_group_1) }
      let!(:facility_manager_access) { create(:access, :manager, user: manager, resource: facility_4) }

      let!(:viewer_access) { create(:access, :viewer, user: viewer, resource: facility_group_2) }
      let!(:facility_viewer_access) { create(:access, :viewer, user: viewer, resource: facility_5) }

      context "view action" do
        it "returns all facilities the manager can view" do
          expect(manager.accesses.facilities(:view)).to contain_exactly(facility_1, facility_4)
          expect(manager.accesses.facilities(:view)).not_to contain_exactly(facility_2, facility_3, facility_5, facility_6)
        end

        it "returns all facilities the viewer can view" do
          expect(viewer.accesses.facilities(:view)).to contain_exactly(facility_2, facility_5)
          expect(viewer.accesses.facilities(:view)).not_to contain_exactly(facility_1, facility_3, facility_4, facility_6)
        end
      end

      context "manage action" do
        it "returns all facilities the manager can manage" do
          expect(manager.accesses.facilities(:manage)).to contain_exactly(facility_1, facility_4)
          expect(manager.accesses.facilities(:manage)).not_to contain_exactly(facility_2, facility_3, facility_5, facility_6)
        end

        it "returns all facilities the viewer can manage" do
          expect(viewer.accesses.facilities(:manage)).to be_empty
        end
      end
    end

    context "for a direct org-level access" do
      let!(:organization_1) { create(:organization) }
      let!(:organization_2) { create(:organization) }
      let!(:organization_3) { create(:organization) }

      let!(:facility_group_1) { create(:facility_group, organization: organization_1) }
      let!(:facility_group_2) { create(:facility_group, organization: organization_2) }
      let!(:facility_group_3) { create(:facility_group, organization: organization_3) }
      let!(:facility_group_4) { create(:facility_group, organization: organization_3) }

      let!(:facility_1) { create(:facility, facility_group: facility_group_1) }
      let!(:facility_2) { create(:facility, facility_group: facility_group_2) }
      let!(:facility_3) { create(:facility, facility_group: facility_group_3) }
      let!(:facility_4) { create(:facility, facility_group: facility_group_4) }
      let!(:facility_5) { create(:facility) }
      let!(:facility_6) { create(:facility) }

      let!(:org_manager_access) { create(:access, :manager, user: manager, resource: organization_1) }
      let!(:fg_manager_access) { create(:access, :manager, user: manager, resource: facility_group_3) }
      let!(:facility_manager_access) { create(:access, :manager, user: manager, resource: facility_5) }

      let!(:viewer_access) { create(:access, :viewer, user: viewer, resource: organization_2) }
      let!(:facility_viewer_access) { create(:access, :viewer, user: viewer, resource: facility_6) }

      context "view action" do
        it "returns all facilities the manager can view" do
          expect(manager.accesses.facilities(:view)).to contain_exactly(facility_1, facility_3, facility_5)
          expect(manager.accesses.facilities(:view)).not_to contain_exactly(facility_2, facility_4, facility_6)
        end

        it "returns all facilities the viewer can view" do
          expect(viewer.accesses.facilities(:view)).to contain_exactly(facility_2, facility_6)
          expect(viewer.accesses.facilities(:view)).not_to contain_exactly(facility_1, facility_3, facility_4, facility_5)
        end
      end

      context "manage action" do
        it "returns all facilities the manager can manage" do
          expect(manager.accesses.facilities(:manage)).to contain_exactly(facility_1, facility_3, facility_5)
          expect(manager.accesses.facilities(:manage)).not_to contain_exactly(facility_2, facility_4, facility_6)
        end

        it "returns all facilities the viewer can manage" do
          expect(viewer.accesses.facilities(:manage)).to be_empty
        end
      end
    end
  end
end
