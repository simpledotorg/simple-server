require "rails_helper"

RSpec.describe Access, type: :model do
  let(:viewer) { create(:admin, :viewer) }
  let(:manager) { create(:admin, :manager) }

  describe "Associations" do
    it { is_expected.to belong_to(:user) }

    context "belongs to resource" do
      let(:facility) { create(:facility) }
      subject { create(:access, user: viewer, resource: facility) }
      it { expect(subject.resource).to be_present }
    end
  end

  describe "Validations" do
    context "resource" do
      let(:admin) { create(:admin) }
      let!(:resource) { create(:facility) }

      it "is invalid if user has more than one access per resource" do
        __valid_access = create(:access, user: viewer, resource: resource)
        invalid_access = build(:access, user: viewer, resource: resource)

        expect(invalid_access).to be_invalid
        expect(invalid_access.errors.messages[:user]).to eq ["can only have 1 access per resource."]
      end

      it "must have a resource" do
        invalid_access = build(:access, user: viewer, resource: nil)

        expect(invalid_access).to be_invalid
        expect(invalid_access.errors.messages[:resource]).to eq ["must exist", "can't be blank"]
      end

      it "does not allow power_user to have accesses (because they have all the access)" do
        power_user = create(:admin, :power_user)
        invalid_access = build(:access, user: power_user, resource: create(:facility))

        expect(invalid_access).to be_invalid
        expect(invalid_access.errors.messages[:user]).to eq ["cannot have accesses if they are a power user."]
      end

      it "is invalid if resource_type is not in the allow-list" do
        valid_access_1 = build(:access, user: viewer, resource: create(:organization))
        valid_access_2 = build(:access, user: viewer, resource: create(:facility_group))
        valid_access_3 = build(:access, user: viewer, resource: create(:facility))
        invalid_access = build(:access, user: viewer, resource: create(:appointment))

        expect(valid_access_1).to be_valid
        expect(valid_access_2).to be_valid
        expect(valid_access_3).to be_valid
        expect(invalid_access).to be_invalid
        expect(invalid_access.errors.messages[:resource_type]).to eq ["is not included in the list"]
      end
    end
  end

  describe ".can?" do
    # let(:super_admin) do
    #   user = create(:admin)
    #   create(:access, :super_admin, user: user)
    #   user
    # end

    context "organizations" do
      let!(:organization_1) { create(:organization) }
      let!(:organization_2) { create(:organization) }
      let!(:organization_3) { create(:organization) }

      context "view action" do
        pending "allows super admin to view anything" do
          expect(super_admin.can?(:view, :organization, organization_1)).to be true
          expect(super_admin.can?(:view, :organization, organization_2)).to be true
          expect(super_admin.can?(:view, :organization, organization_3)).to be true
          expect(super_admin.can?(:view, :organization)).to be true
        end

        it "allows manager to view" do
          create(:access, user: manager, resource: organization_1)

          expect(manager.can?(:view, :organization, organization_1)).to be true
          expect(manager.can?(:view, :organization, organization_2)).to be false
          expect(manager.can?(:view, :organization, organization_3)).to be false
          expect(manager.can?(:view, :organization)).to be true
        end

        it "allows viewer to view" do
          create(:access, user: viewer, resource: organization_3)

          expect(viewer.can?(:view, :organization, organization_1)).to be false
          expect(viewer.can?(:view, :organization, organization_2)).to be false
          expect(viewer.can?(:view, :organization, organization_3)).to be true
          expect(viewer.can?(:view, :organization)).to be true
        end
      end

      context "manage action" do
        pending "allows super admin to manage anything" do
          expect(super_admin.can?(:manage, :organization, organization_1)).to be true
          expect(super_admin.can?(:manage, :organization, organization_2)).to be true
          expect(super_admin.can?(:manage, :organization, organization_3)).to be true
          expect(super_admin.can?(:manage, :organization)).to be true
        end

        it "allows manager to manage" do
          create(:access, user: manager, resource: organization_1)

          expect(manager.can?(:manage, :organization, organization_1)).to be true
          expect(manager.can?(:manage, :organization, organization_2)).to be false
          expect(manager.can?(:manage, :organization, organization_3)).to be false
          expect(manager.can?(:manage, :organization)).to be true
        end

        it "allows viewer to manage" do
          create(:access, user: viewer, resource: organization_3)

          expect(viewer.can?(:manage, :organization, organization_1)).to be false
          expect(viewer.can?(:manage, :organization, organization_2)).to be false
          expect(viewer.can?(:manage, :organization, organization_3)).to be false
          expect(viewer.can?(:manage, :organization)).to be false
        end
      end
    end

    context "facility_groups" do
      let!(:facility_group_1) { create(:facility_group) }
      let!(:facility_group_2) { create(:facility_group) }
      let!(:facility_group_3) { create(:facility_group) }

      context "view action" do
        pending "allows super admin to view anything" do
          expect(super_admin.can?(:view, :facility_group, facility_group_1)).to be true
          expect(super_admin.can?(:view, :facility_group, facility_group_2)).to be true
          expect(super_admin.can?(:view, :facility_group, facility_group_3)).to be true
          expect(super_admin.can?(:view, :facility_group)).to be true
        end

        it "allows manager to view" do
          create(:access, user: manager, resource: facility_group_1)

          expect(manager.can?(:view, :facility_group, facility_group_1)).to be true
          expect(manager.can?(:view, :facility_group, facility_group_2)).to be false
          expect(manager.can?(:view, :facility_group, facility_group_3)).to be false
          expect(manager.can?(:view, :facility_group)).to be true
        end

        it "allows viewer to view" do
          create(:access, user: viewer, resource: facility_group_3)

          expect(viewer.can?(:view, :facility_group, facility_group_1)).to be false
          expect(viewer.can?(:view, :facility_group, facility_group_2)).to be false
          expect(viewer.can?(:view, :facility_group, facility_group_3)).to be true
          expect(viewer.can?(:view, :facility_group)).to be true
        end
      end

      context "manage action" do
        pending "allows super admin to manage anything" do
          expect(super_admin.can?(:manage, :facility_group, facility_group_1)).to be true
          expect(super_admin.can?(:manage, :facility_group, facility_group_2)).to be true
          expect(super_admin.can?(:manage, :facility_group, facility_group_3)).to be true
          expect(super_admin.can?(:manage, :facility_group)).to be true
        end

        it "allows manager to manage" do
          create(:access, user: manager, resource: facility_group_1)

          expect(manager.can?(:manage, :facility_group, facility_group_1)).to be true
          expect(manager.can?(:manage, :facility_group, facility_group_2)).to be false
          expect(manager.can?(:manage, :facility_group, facility_group_3)).to be false
          expect(manager.can?(:manage, :facility_group)).to be true
        end

        it "allows viewer to manage" do
          create(:access, user: viewer, resource: facility_group_3)

          expect(viewer.can?(:manage, :facility_group, facility_group_1)).to be false
          expect(viewer.can?(:manage, :facility_group, facility_group_2)).to be false
          expect(viewer.can?(:manage, :facility_group, facility_group_3)).to be false
          expect(viewer.can?(:manage, :facility_group)).to be false
        end
      end

      context "when org-level access" do
        let!(:organization_1) { create(:organization) }
        let!(:facility_group_1) { create(:facility_group, organization: organization_1) }
        let!(:facility_group_2) { create(:facility_group) }
        let!(:facility_group_3) { create(:facility_group) }

        it "allows manager to view" do
          create(:access, user: manager, resource: organization_1)
          create(:access, user: manager, resource: facility_group_2)

          expect(manager.can?(:view, :facility_group, facility_group_1)).to be true
          expect(manager.can?(:view, :facility_group, facility_group_2)).to be true
          expect(manager.can?(:view, :facility_group, facility_group_3)).to be false
          expect(manager.can?(:view, :facility_group)).to be true
        end

        it "allows viewer to view" do
          create(:access, user: viewer, resource: organization_1)
          create(:access, user: viewer, resource: facility_group_2)

          expect(viewer.can?(:view, :facility_group, facility_group_1)).to be true
          expect(viewer.can?(:view, :facility_group, facility_group_2)).to be true
          expect(viewer.can?(:view, :facility_group, facility_group_3)).to be false
          expect(viewer.can?(:view, :facility_group)).to be true
        end

        it "does not allow viewer to manage" do
          create(:access, user: viewer, resource: organization_1)
          create(:access, user: viewer, resource: facility_group_2)

          expect(viewer.can?(:manage, :facility_group, facility_group_1)).to be false
          expect(viewer.can?(:manage, :facility_group, facility_group_2)).to be false
          expect(viewer.can?(:manage, :facility_group, facility_group_3)).to be false
          expect(viewer.can?(:manage, :facility_group)).to be false
        end

        it "allows manager to manage" do
          create(:access, user: manager, resource: organization_1)
          create(:access, user: manager, resource: facility_group_2)

          expect(manager.can?(:manage, :facility_group, facility_group_1)).to be true
          expect(manager.can?(:manage, :facility_group, facility_group_2)).to be true
          expect(manager.can?(:manage, :facility_group, facility_group_3)).to be false
          expect(manager.can?(:manage, :facility_group)).to be true
        end
      end
    end

    context "facility" do
      let!(:facility_1) { create(:facility) }
      let!(:facility_2) { create(:facility) }
      let!(:facility_3) { create(:facility) }

      context "view action" do
        pending "allows super admin to view anything" do
          expect(super_admin.can?(:view, :facility, facility_1)).to be true
          expect(super_admin.can?(:view, :facility, facility_2)).to be true
          expect(super_admin.can?(:view, :facility, facility_3)).to be true
          expect(super_admin.can?(:view, :facility)).to be true
        end

        it "allows manager to view" do
          create(:access, user: manager, resource: facility_1)

          expect(manager.can?(:view, :facility, facility_1)).to be true
          expect(manager.can?(:view, :facility, facility_2)).to be false
          expect(manager.can?(:view, :facility, facility_3)).to be false
          expect(manager.can?(:view, :facility)).to be true
        end

        it "allows viewer to view" do
          create(:access, user: viewer, resource: facility_3)

          expect(viewer.can?(:view, :facility, facility_1)).to be false
          expect(viewer.can?(:view, :facility, facility_2)).to be false
          expect(viewer.can?(:view, :facility, facility_3)).to be true
          expect(viewer.can?(:view, :facility)).to be true
        end
      end

      context "manage action" do
        pending "allows super admin to manage anything" do
          expect(super_admin.can?(:manage, :facility, facility_1)).to be true
          expect(super_admin.can?(:manage, :facility, facility_2)).to be true
          expect(super_admin.can?(:manage, :facility, facility_3)).to be true
          expect(super_admin.can?(:manage, :facility)).to be true
        end

        it "allows manager to manage" do
          create(:access, user: manager, resource: facility_1)

          expect(manager.can?(:manage, :facility, facility_1)).to be true
          expect(manager.can?(:manage, :facility, facility_2)).to be false
          expect(manager.can?(:manage, :facility, facility_3)).to be false
          expect(manager.can?(:manage, :facility)).to be true
        end

        it "allows viewer to manage" do
          create(:access, user: viewer, resource: facility_3)

          expect(viewer.can?(:manage, :facility, facility_1)).to be false
          expect(viewer.can?(:manage, :facility, facility_2)).to be false
          expect(viewer.can?(:manage, :facility, facility_3)).to be false
          expect(viewer.can?(:manage, :facility)).to be false
        end
      end

      context "when facility-group-level access" do
        let!(:facility_group_1) { create(:facility_group) }
        let!(:facility_1) { create(:facility, facility_group: facility_group_1) }
        let!(:facility_2) { create(:facility) }
        let!(:facility_3) { create(:facility) }

        it "allows manager to view" do
          create(:access, user: manager, resource: facility_group_1)
          create(:access, user: manager, resource: facility_2)

          expect(manager.can?(:view, :facility, facility_1)).to be true
          expect(manager.can?(:view, :facility, facility_2)).to be true
          expect(manager.can?(:view, :facility, facility_3)).to be false
          expect(manager.can?(:view, :facility)).to be true
        end

        it "allows viewer to view" do
          create(:access, user: viewer, resource: facility_group_1)
          create(:access, user: viewer, resource: facility_2)

          expect(viewer.can?(:view, :facility, facility_1)).to be true
          expect(viewer.can?(:view, :facility, facility_2)).to be true
          expect(viewer.can?(:view, :facility, facility_3)).to be false
          expect(viewer.can?(:view, :facility)).to be true
        end

        it "does not allow viewer to manage" do
          create(:access, user: viewer, resource: facility_group_1)
          create(:access, user: viewer, resource: facility_2)

          expect(viewer.can?(:manage, :facility, facility_1)).to be false
          expect(viewer.can?(:manage, :facility, facility_2)).to be false
          expect(viewer.can?(:manage, :facility, facility_3)).to be false
          expect(viewer.can?(:manage, :facility)).to be false
        end

        it "allows manager to manage" do
          create(:access, user: manager, resource: facility_group_1)
          create(:access, user: manager, resource: facility_2)

          expect(manager.can?(:manage, :facility, facility_1)).to be true
          expect(manager.can?(:manage, :facility, facility_2)).to be true
          expect(manager.can?(:manage, :facility, facility_3)).to be false
          expect(manager.can?(:manage, :facility)).to be true
        end
      end

      context "when org-level access" do
        let!(:organization_1) { create(:organization) }
        let!(:facility_group_1) { create(:facility_group, organization: organization_1) }
        let!(:facility_1) { create(:facility, facility_group: facility_group_1) }
        let!(:facility_2) { create(:facility) }
        let!(:facility_3) { create(:facility) }

        it "allows manager to view" do
          create(:access, user: manager, resource: organization_1)
          create(:access, user: manager, resource: facility_2)

          expect(manager.can?(:view, :facility, facility_1)).to be true
          expect(manager.can?(:view, :facility, facility_2)).to be true
          expect(manager.can?(:view, :facility, facility_3)).to be false
          expect(manager.can?(:view, :facility)).to be true
        end

        it "allows viewer to view" do
          create(:access, user: viewer, resource: organization_1)
          create(:access, user: viewer, resource: facility_2)

          expect(viewer.can?(:view, :facility, facility_1)).to be true
          expect(viewer.can?(:view, :facility, facility_2)).to be true
          expect(viewer.can?(:view, :facility, facility_3)).to be false
          expect(viewer.can?(:view, :facility)).to be true
        end

        it "does not allow viewer to manage" do
          create(:access, user: viewer, resource: organization_1)
          create(:access, user: viewer, resource: facility_2)

          expect(viewer.can?(:manage, :facility, facility_1)).to be false
          expect(viewer.can?(:manage, :facility, facility_2)).to be false
          expect(viewer.can?(:manage, :facility, facility_3)).to be false
          expect(viewer.can?(:manage, :facility)).to be false
        end

        it "allows manager to manage" do
          create(:access, user: manager, resource: organization_1)
          create(:access, user: manager, resource: facility_2)

          expect(manager.can?(:manage, :facility, facility_1)).to be true
          expect(manager.can?(:manage, :facility, facility_2)).to be true
          expect(manager.can?(:manage, :facility, facility_3)).to be false
          expect(manager.can?(:manage, :facility)).to be true
        end
      end
    end
  end

  describe ".organizations" do
    let!(:organization_1) { create(:organization) }
    let!(:organization_2) { create(:organization) }
    let!(:organization_3) { create(:organization) }
    let!(:viewer_access) { create(:access, user: viewer, resource: organization_2) }
    let!(:manager_access) { create(:access, user: manager, resource: organization_1) }

    context "view action" do
      it "returns all organizations the manager can view" do
        expect(manager.accesses.organizations(:view)).to contain_exactly(organization_1)
        expect(manager.accesses.organizations(:view)).not_to contain_exactly(organization_2)
      end

      it "returns all organizations the viewer can view" do
        expect(viewer.accesses.organizations(:view)).to contain_exactly(organization_2)
        expect(viewer.accesses.organizations(:view)).not_to contain_exactly(organization_1)
      end
    end

    context "manage action" do
      it "returns all organizations the manager can manage" do
        expect(manager.accesses.organizations(:manage)).to contain_exactly(organization_1)
        expect(manager.accesses.organizations(:manage)).not_to contain_exactly(organization_2)
      end

      it "returns all organizations the viewer can manage" do
        expect(viewer.accesses.organizations(:manage)).to be_empty
      end
    end
  end

  describe ".facility_groups" do
    context "for a direct facility-group-level access" do
      let!(:facility_group_1) { create(:facility_group) }
      let!(:facility_group_2) { create(:facility_group) }
      let!(:facility_group_3) { create(:facility_group) }
      let!(:manager_access) { create(:access, user: manager, resource: facility_group_1) }
      let!(:viewer_access) { create(:access, user: viewer, resource: facility_group_2) }

      context "view action" do
        it "returns all facility_groups the manager can view" do
          expect(manager.accesses.facility_groups(:view)).to contain_exactly(facility_group_1)
          expect(manager.accesses.facility_groups(:view)).not_to contain_exactly(facility_group_2, facility_group_3)
        end

        it "returns all facility_groups the viewer can view" do
          expect(viewer.accesses.facility_groups(:view)).to contain_exactly(facility_group_2)
          expect(viewer.accesses.facility_groups(:view)).not_to contain_exactly(facility_group_1, facility_group_3)
        end
      end

      context "manage action" do
        it "returns all facility_groups the manager can manage" do
          expect(manager.accesses.facility_groups(:manage)).to contain_exactly(facility_group_1)
          expect(manager.accesses.facility_groups(:manage)).not_to contain_exactly(facility_group_2, facility_group_3)
        end

        it "returns all facility_groups the viewer can manage" do
          expect(viewer.accesses.facility_groups(:manage)).to be_empty
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

      let!(:org_manager_access) { create(:access, user: manager, resource: organization_1) }
      let!(:fg_manager_access) { create(:access, user: manager, resource: facility_group_3) }

      let!(:org_viewer_access) { create(:access, user: viewer, resource: organization_2) }
      let!(:fg_viewer_access) { create(:access, user: viewer, resource: facility_group_4) }

      context "view action" do
        it "returns all facilities the manager can view" do
          expect(manager.accesses.facility_groups(:view)).to contain_exactly(facility_group_1, facility_group_3)
          expect(manager.accesses.facility_groups(:view)).not_to contain_exactly(facility_group_2, facility_group_4)
        end

        it "returns all facility_groups the viewer can view" do
          expect(viewer.accesses.facility_groups(:view)).to contain_exactly(facility_group_2, facility_group_4)
          expect(viewer.accesses.facility_groups(:view)).not_to contain_exactly(facility_group_1, facility_group_3)
        end
      end

      context "manage action" do
        it "returns all facility_groups the manager can manage" do
          expect(manager.accesses.facility_groups(:manage)).to contain_exactly(facility_group_1, facility_group_3)
          expect(manager.accesses.facility_groups(:manage)).not_to contain_exactly(facility_group_2, facility_group_4)
        end

        it "returns all facility_groups the viewer can manage" do
          expect(viewer.accesses.facility_groups(:manage)).to be_empty
        end
      end
    end
  end

  describe ".facilities" do
    context "for a direct facility-level access" do
      let!(:facility_1) { create(:facility) }
      let!(:facility_2) { create(:facility) }
      let!(:facility_3) { create(:facility) }
      let!(:manager_access) { create(:access, user: manager, resource: facility_1) }
      let!(:viewer_access) { create(:access, user: viewer, resource: facility_2) }

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

      let!(:manager_access) { create(:access, user: manager, resource: facility_group_1) }
      let!(:facility_manager_access) { create(:access, user: manager, resource: facility_4) }

      let!(:viewer_access) { create(:access, user: viewer, resource: facility_group_2) }
      let!(:facility_viewer_access) { create(:access, user: viewer, resource: facility_5) }

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

      let!(:org_manager_access) { create(:access, user: manager, resource: organization_1) }
      let!(:fg_manager_access) { create(:access, user: manager, resource: facility_group_3) }
      let!(:facility_manager_access) { create(:access, user: manager, resource: facility_5) }

      let!(:viewer_access) { create(:access, user: viewer, resource: organization_2) }
      let!(:facility_viewer_access) { create(:access, user: viewer, resource: facility_6) }

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
