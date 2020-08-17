require "rails_helper"

RSpec.describe Access, type: :model do
  let(:viewer_all) { create(:admin, :viewer_all) }
  let(:manager) { create(:admin, :manager) }

  describe "Associations" do
    it { is_expected.to belong_to(:user) }

    context "belongs to resource" do
      let(:facility) { create(:facility) }
      subject { create(:access, user: viewer_all, resource: facility) }
      it { expect(subject.resource).to be_present }
    end
  end

  describe "Validations" do
    context "resource" do
      let(:admin) { create(:admin) }
      let!(:resource) { create(:facility) }

      it "does not allow a power_user to have accesses (because they have all the access)" do
        power_user = create(:admin, :power_user)
        invalid_access = build(:access, user: power_user, resource: create(:facility))

        expect(invalid_access).to be_invalid
        expect(invalid_access.errors.messages[:user]).to eq ["cannot have accesses if they are a power user."]
      end

      it "is invalid if user has more than one access per resource" do
        __valid_access = create(:access, user: viewer_all, resource: resource)
        invalid_access = build(:access, user: viewer_all, resource: resource)

        expect(invalid_access).to be_invalid
        expect(invalid_access.errors.messages[:user]).to eq ["can only have 1 access per resource."]
      end

      it "must have a resource" do
        invalid_access = build(:access, user: viewer_all, resource: nil)

        expect(invalid_access).to be_invalid
        expect(invalid_access.errors.messages[:resource]).to eq ["must exist", "can't be blank"]
      end

      it "is invalid if resource_type is not in the allow-list" do
        valid_access_1 = build(:access, user: viewer_all, resource: create(:organization))
        valid_access_2 = build(:access, user: viewer_all, resource: create(:facility_group))
        valid_access_3 = build(:access, user: viewer_all, resource: create(:facility))
        invalid_access = build(:access, user: viewer_all, resource: create(:appointment))

        expect(valid_access_1).to be_valid
        expect(valid_access_2).to be_valid
        expect(valid_access_3).to be_valid
        expect(invalid_access).to be_invalid
        expect(invalid_access.errors.messages[:resource_type]).to eq ["is not included in the list"]
      end
    end
  end

  describe ".can?" do
    context "organizations" do
      let!(:organization_1) { create(:organization) }
      let!(:organization_2) { create(:organization) }
      let!(:organization_3) { create(:organization) }

      context "view_pii action" do
        it "allows manager to view_pii" do
          create(:access, user: manager, resource: organization_1)

          expect(manager.can?(:view_pii, :organization, organization_1)).to be true
          expect(manager.can?(:view_pii, :organization, organization_2)).to be false
          expect(manager.can?(:view_pii, :organization, organization_3)).to be false
          expect(manager.can?(:view_pii, :organization)).to be true
        end

        it "allows viewer_all to view_pii" do
          create(:access, user: viewer_all, resource: organization_3)

          expect(viewer_all.can?(:view_pii, :organization, organization_1)).to be false
          expect(viewer_all.can?(:view_pii, :organization, organization_2)).to be false
          expect(viewer_all.can?(:view_pii, :organization, organization_3)).to be true
          expect(viewer_all.can?(:view_pii, :organization)).to be true
        end
      end

      context "manage action" do
        it "allows manager to manage" do
          create(:access, user: manager, resource: organization_1)

          expect(manager.can?(:manage, :organization, organization_1)).to be true
          expect(manager.can?(:manage, :organization, organization_2)).to be false
          expect(manager.can?(:manage, :organization, organization_3)).to be false
          expect(manager.can?(:manage, :organization)).to be true
        end

        it "allows viewer_all to manage" do
          create(:access, user: viewer_all, resource: organization_3)

          expect(viewer_all.can?(:manage, :organization, organization_1)).to be false
          expect(viewer_all.can?(:manage, :organization, organization_2)).to be false
          expect(viewer_all.can?(:manage, :organization, organization_3)).to be false
          expect(viewer_all.can?(:manage, :organization)).to be false
        end
      end
    end

    context "facility_groups" do
      let!(:facility_group_1) { create(:facility_group) }
      let!(:facility_group_2) { create(:facility_group) }
      let!(:facility_group_3) { create(:facility_group) }

      context "view_pii action" do
        it "allows manager to view_pii" do
          create(:access, user: manager, resource: facility_group_1)

          expect(manager.can?(:view_pii, :facility_group, facility_group_1)).to be true
          expect(manager.can?(:view_pii, :facility_group, facility_group_2)).to be false
          expect(manager.can?(:view_pii, :facility_group, facility_group_3)).to be false
          expect(manager.can?(:view_pii, :facility_group)).to be true
        end

        it "allows viewer_all to view_pii" do
          create(:access, user: viewer_all, resource: facility_group_3)

          expect(viewer_all.can?(:view_pii, :facility_group, facility_group_1)).to be false
          expect(viewer_all.can?(:view_pii, :facility_group, facility_group_2)).to be false
          expect(viewer_all.can?(:view_pii, :facility_group, facility_group_3)).to be true
          expect(viewer_all.can?(:view_pii, :facility_group)).to be true
        end
      end

      context "manage action" do
        it "allows manager to manage" do
          create(:access, user: manager, resource: facility_group_1)

          expect(manager.can?(:manage, :facility_group, facility_group_1)).to be true
          expect(manager.can?(:manage, :facility_group, facility_group_2)).to be false
          expect(manager.can?(:manage, :facility_group, facility_group_3)).to be false
          expect(manager.can?(:manage, :facility_group)).to be true
        end

        it "allows viewer_all to manage" do
          create(:access, user: viewer_all, resource: facility_group_3)

          expect(viewer_all.can?(:manage, :facility_group, facility_group_1)).to be false
          expect(viewer_all.can?(:manage, :facility_group, facility_group_2)).to be false
          expect(viewer_all.can?(:manage, :facility_group, facility_group_3)).to be false
          expect(viewer_all.can?(:manage, :facility_group)).to be false
        end
      end

      context "when org-level access" do
        let!(:organization_1) { create(:organization) }
        let!(:facility_group_1) { create(:facility_group, organization: organization_1) }
        let!(:facility_group_2) { create(:facility_group) }
        let!(:facility_group_3) { create(:facility_group) }

        it "allows manager to view_pii" do
          create(:access, user: manager, resource: organization_1)
          create(:access, user: manager, resource: facility_group_2)

          expect(manager.can?(:view_pii, :facility_group, facility_group_1)).to be true
          expect(manager.can?(:view_pii, :facility_group, facility_group_2)).to be true
          expect(manager.can?(:view_pii, :facility_group, facility_group_3)).to be false
          expect(manager.can?(:view_pii, :facility_group)).to be true
        end

        it "allows viewer_all to view_pii" do
          create(:access, user: viewer_all, resource: organization_1)
          create(:access, user: viewer_all, resource: facility_group_2)

          expect(viewer_all.can?(:view_pii, :facility_group, facility_group_1)).to be true
          expect(viewer_all.can?(:view_pii, :facility_group, facility_group_2)).to be true
          expect(viewer_all.can?(:view_pii, :facility_group, facility_group_3)).to be false
          expect(viewer_all.can?(:view_pii, :facility_group)).to be true
        end

        it "does not allow viewer_all to manage" do
          create(:access, user: viewer_all, resource: organization_1)
          create(:access, user: viewer_all, resource: facility_group_2)

          expect(viewer_all.can?(:manage, :facility_group, facility_group_1)).to be false
          expect(viewer_all.can?(:manage, :facility_group, facility_group_2)).to be false
          expect(viewer_all.can?(:manage, :facility_group, facility_group_3)).to be false
          expect(viewer_all.can?(:manage, :facility_group)).to be false
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

      context "view_pii action" do

        it "allows manager to view_pii_pii" do
          create(:access, user: manager, resource: facility_1)

          expect(manager.can?(:view_pii, :facility, facility_1)).to be true
          expect(manager.can?(:view_pii, :facility, facility_2)).to be false
          expect(manager.can?(:view_pii, :facility, facility_3)).to be false
          expect(manager.can?(:view_pii, :facility)).to be true
        end

        it "allows viewer_all to view_pii" do
          create(:access, user: viewer_all, resource: facility_3)

          expect(viewer_all.can?(:view_pii, :facility, facility_1)).to be false
          expect(viewer_all.can?(:view_pii, :facility, facility_2)).to be false
          expect(viewer_all.can?(:view_pii, :facility, facility_3)).to be true
          expect(viewer_all.can?(:view_pii, :facility)).to be true
        end
      end

      context "manage action" do
        it "allows manager to manage" do
          create(:access, user: manager, resource: facility_1)

          expect(manager.can?(:manage, :facility, facility_1)).to be true
          expect(manager.can?(:manage, :facility, facility_2)).to be false
          expect(manager.can?(:manage, :facility, facility_3)).to be false
          expect(manager.can?(:manage, :facility)).to be true
        end

        it "allows viewer_all to manage" do
          create(:access, user: viewer_all, resource: facility_3)

          expect(viewer_all.can?(:manage, :facility, facility_1)).to be false
          expect(viewer_all.can?(:manage, :facility, facility_2)).to be false
          expect(viewer_all.can?(:manage, :facility, facility_3)).to be false
          expect(viewer_all.can?(:manage, :facility)).to be false
        end
      end

      context "when facility-group-level access" do
        let!(:facility_group_1) { create(:facility_group) }
        let!(:facility_1) { create(:facility, facility_group: facility_group_1) }
        let!(:facility_2) { create(:facility) }
        let!(:facility_3) { create(:facility) }

        it "allows manager to view_pii" do
          create(:access, user: manager, resource: facility_group_1)
          create(:access, user: manager, resource: facility_2)

          expect(manager.can?(:view_pii, :facility, facility_1)).to be true
          expect(manager.can?(:view_pii, :facility, facility_2)).to be true
          expect(manager.can?(:view_pii, :facility, facility_3)).to be false
          expect(manager.can?(:view_pii, :facility)).to be true
        end

        it "allows viewer_all to view_pii" do
          create(:access, user: viewer_all, resource: facility_group_1)
          create(:access, user: viewer_all, resource: facility_2)

          expect(viewer_all.can?(:view_pii, :facility, facility_1)).to be true
          expect(viewer_all.can?(:view_pii, :facility, facility_2)).to be true
          expect(viewer_all.can?(:view_pii, :facility, facility_3)).to be false
          expect(viewer_all.can?(:view_pii, :facility)).to be true
        end

        it "does not allow viewer_all to manage" do
          create(:access, user: viewer_all, resource: facility_group_1)
          create(:access, user: viewer_all, resource: facility_2)

          expect(viewer_all.can?(:manage, :facility, facility_1)).to be false
          expect(viewer_all.can?(:manage, :facility, facility_2)).to be false
          expect(viewer_all.can?(:manage, :facility, facility_3)).to be false
          expect(viewer_all.can?(:manage, :facility)).to be false
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

        it "allows manager to view_pii" do
          create(:access, user: manager, resource: organization_1)
          create(:access, user: manager, resource: facility_2)

          expect(manager.can?(:view_pii, :facility, facility_1)).to be true
          expect(manager.can?(:view_pii, :facility, facility_2)).to be true
          expect(manager.can?(:view_pii, :facility, facility_3)).to be false
          expect(manager.can?(:view_pii, :facility)).to be true
        end

        it "allows viewer_all to view_pii" do
          create(:access, user: viewer_all, resource: organization_1)
          create(:access, user: viewer_all, resource: facility_2)

          expect(viewer_all.can?(:view_pii, :facility, facility_1)).to be true
          expect(viewer_all.can?(:view_pii, :facility, facility_2)).to be true
          expect(viewer_all.can?(:view_pii, :facility, facility_3)).to be false
          expect(viewer_all.can?(:view_pii, :facility)).to be true
        end

        it "does not allow viewer_all to manage" do
          create(:access, user: viewer_all, resource: organization_1)
          create(:access, user: viewer_all, resource: facility_2)

          expect(viewer_all.can?(:manage, :facility, facility_1)).to be false
          expect(viewer_all.can?(:manage, :facility, facility_2)).to be false
          expect(viewer_all.can?(:manage, :facility, facility_3)).to be false
          expect(viewer_all.can?(:manage, :facility)).to be false
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

    context "for a direct organization-level access" do
      let!(:viewer_all_access) { create(:access, user: viewer_all, resource: organization_2) }
      let!(:manager_access) { create(:access, user: manager, resource: organization_1) }

      context "view_pii action" do
        it "returns all organizations the manager can view" do
          expect(manager.accesses.organizations(:view_pii)).to contain_exactly(organization_1)
          expect(manager.accesses.organizations(:view_pii)).not_to contain_exactly(organization_2)
        end

        it "returns all organizations the viewer_all can view" do
          expect(viewer_all.accesses.organizations(:view_pii)).to contain_exactly(organization_2)
          expect(viewer_all.accesses.organizations(:view_pii)).not_to contain_exactly(organization_1)
        end
      end

      context "manage action" do
        it "returns all organizations the manager can manage" do
          expect(manager.accesses.organizations(:manage)).to contain_exactly(organization_1)
          expect(manager.accesses.organizations(:manage)).not_to contain_exactly(organization_2)
        end

        it "returns all organizations the viewer_all can manage" do
          expect(viewer_all.accesses.organizations(:manage)).to be_empty
        end
      end
    end

    context "for a lower-level access than organization" do
      context "facility_group access" do
        let!(:viewer_all_access) { create(:access, user: viewer_all, resource: create(:facility_group)) }
        let!(:manager_access) { create(:access, user: manager, resource: create(:facility_group)) }

        it "returns no organizations" do
          expect(viewer_all.accesses.organizations(:view_pii)).to be_empty
          expect(manager.accesses.organizations(:view_pii)).to be_empty
          expect(viewer_all.accesses.organizations(:manage)).to be_empty
          expect(manager.accesses.organizations(:manage)).to be_empty
        end
      end

      context "facility access" do
        let!(:viewer_all_access) { create(:access, user: viewer_all, resource: create(:facility)) }
        let!(:manager_access) { create(:access, user: manager, resource: create(:facility)) }

        it "returns no organizations" do
          expect(viewer_all.accesses.organizations(:view_pii)).to be_empty
          expect(manager.accesses.organizations(:view_pii)).to be_empty
          expect(viewer_all.accesses.organizations(:manage)).to be_empty
          expect(manager.accesses.organizations(:manage)).to be_empty
        end
      end
    end
  end

  describe ".facility_groups" do
    context "for a direct facility-group-level access" do
      let!(:facility_group_1) { create(:facility_group) }
      let!(:facility_group_2) { create(:facility_group) }
      let!(:facility_group_3) { create(:facility_group) }
      let!(:manager_access) { create(:access, user: manager, resource: facility_group_1) }
      let!(:viewer_all_access) { create(:access, user: viewer_all, resource: facility_group_2) }

      context "view_pii action" do
        it "returns all facility_groups the manager can view" do
          expect(manager.accesses.facility_groups(:view_pii)).to contain_exactly(facility_group_1)
          expect(manager.accesses.facility_groups(:view_pii)).not_to contain_exactly(facility_group_2, facility_group_3)
        end

        it "returns all facility_groups the viewer_all can view" do
          expect(viewer_all.accesses.facility_groups(:view_pii)).to contain_exactly(facility_group_2)
          expect(viewer_all.accesses.facility_groups(:view_pii)).not_to contain_exactly(facility_group_1, facility_group_3)
        end
      end

      context "manage action" do
        it "returns all facility_groups the manager can manage" do
          expect(manager.accesses.facility_groups(:manage)).to contain_exactly(facility_group_1)
          expect(manager.accesses.facility_groups(:manage)).not_to contain_exactly(facility_group_2, facility_group_3)
        end

        it "returns all facility_groups the viewer_all can manage" do
          expect(viewer_all.accesses.facility_groups(:manage)).to be_empty
        end
      end
    end

    context "for a higher-level organization access" do
      let!(:organization_1) { create(:organization) }
      let!(:organization_2) { create(:organization) }
      let!(:organization_3) { create(:organization) }

      let!(:facility_group_1) { create(:facility_group, organization: organization_1) }
      let!(:facility_group_2) { create(:facility_group, organization: organization_2) }
      let!(:facility_group_3) { create(:facility_group, organization: organization_3) }
      let!(:facility_group_4) { create(:facility_group, organization: organization_3) }

      let!(:org_manager_access) { create(:access, user: manager, resource: organization_1) }
      let!(:fg_manager_access) { create(:access, user: manager, resource: facility_group_3) }

      let!(:org_viewer_all_access) { create(:access, user: viewer_all, resource: organization_2) }
      let!(:fg_viewer_all_access) { create(:access, user: viewer_all, resource: facility_group_4) }

      context "view_pii action" do
        it "returns all facilities the manager can view" do
          expect(manager.accesses.facility_groups(:view_pii)).to contain_exactly(facility_group_1, facility_group_3)
          expect(manager.accesses.facility_groups(:view_pii)).not_to contain_exactly(facility_group_2, facility_group_4)
        end

        it "returns all facility_groups the viewer_all can view" do
          expect(viewer_all.accesses.facility_groups(:view_pii)).to contain_exactly(facility_group_2, facility_group_4)
          expect(viewer_all.accesses.facility_groups(:view_pii)).not_to contain_exactly(facility_group_1, facility_group_3)
        end
      end

      context "manage action" do
        it "returns all facility_groups the manager can manage" do
          expect(manager.accesses.facility_groups(:manage)).to contain_exactly(facility_group_1, facility_group_3)
          expect(manager.accesses.facility_groups(:manage)).not_to contain_exactly(facility_group_2, facility_group_4)
        end

        it "returns all facility_groups the viewer_all can manage" do
          expect(viewer_all.accesses.facility_groups(:manage)).to be_empty
        end
      end
    end

    context "for a lower-level access than facility_group or organization" do
      context "facility access" do
        let!(:viewer_all_access) { create(:access, user: viewer_all, resource: create(:facility)) }
        let!(:manager_access) { create(:access, user: manager, resource: create(:facility)) }

        it "returns no facility_groups" do
          expect(viewer_all.accesses.facility_groups(:view_pii)).to be_empty
          expect(manager.accesses.facility_groups(:view_pii)).to be_empty
          expect(viewer_all.accesses.facility_groups(:manage)).to be_empty
          expect(manager.accesses.facility_groups(:manage)).to be_empty
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
      let!(:viewer_all_access) { create(:access, user: viewer_all, resource: facility_2) }

      context "view_pii action" do
        it "returns all facilities the manager can view" do
          expect(manager.accesses.facilities(:view_pii)).to contain_exactly(facility_1)
          expect(manager.accesses.facilities(:view_pii)).not_to contain_exactly(facility_2, facility_3)
        end

        it "returns all facilities the viewer_all can view" do
          expect(viewer_all.accesses.facilities(:view_pii)).to contain_exactly(facility_2)
          expect(viewer_all.accesses.facilities(:view_pii)).not_to contain_exactly(facility_1, facility_3)
        end
      end

      context "manage action" do
        it "returns all facilities the manager can manage" do
          expect(manager.accesses.facilities(:manage)).to contain_exactly(facility_1)
          expect(manager.accesses.facilities(:manage)).not_to contain_exactly(facility_2, facility_3)
        end

        it "returns all facilities the viewer_all can manage" do
          expect(viewer_all.accesses.facilities(:manage)).to be_empty
        end
      end
    end

    context "for a higher-level facility_group access" do
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

      let!(:viewer_all_access) { create(:access, user: viewer_all, resource: facility_group_2) }
      let!(:facility_viewer_all_access) { create(:access, user: viewer_all, resource: facility_5) }

      context "view_pii action" do
        it "returns all facilities the manager can view" do
          expect(manager.accesses.facilities(:view_pii)).to contain_exactly(facility_1, facility_4)
          expect(manager.accesses.facilities(:view_pii)).not_to contain_exactly(facility_2, facility_3, facility_5, facility_6)
        end

        it "returns all facilities the viewer_all can view" do
          expect(viewer_all.accesses.facilities(:view_pii)).to contain_exactly(facility_2, facility_5)
          expect(viewer_all.accesses.facilities(:view_pii)).not_to contain_exactly(facility_1, facility_3, facility_4, facility_6)
        end
      end

      context "manage action" do
        it "returns all facilities the manager can manage" do
          expect(manager.accesses.facilities(:manage)).to contain_exactly(facility_1, facility_4)
          expect(manager.accesses.facilities(:manage)).not_to contain_exactly(facility_2, facility_3, facility_5, facility_6)
        end

        it "returns all facilities the viewer_all can manage" do
          expect(viewer_all.accesses.facilities(:manage)).to be_empty
        end
      end
    end

    context "for a higher-level organization access" do
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
      let!(:viewer_all_access) { create(:access, user: viewer_all, resource: organization_2) }
      let!(:facility_viewer_all_access) { create(:access, user: viewer_all, resource: facility_6) }


      context "view_pii action" do
        it "returns all facilities the manager can view" do
          expect(manager.accesses.facilities(:view_pii)).to contain_exactly(facility_1, facility_3, facility_5)
          expect(manager.accesses.facilities(:view_pii)).not_to contain_exactly(facility_2, facility_4, facility_6)
        end

        it "returns all facilities the viewer_all can view" do
          expect(viewer_all.accesses.facilities(:view_pii)).to contain_exactly(facility_2, facility_6)
          expect(viewer_all.accesses.facilities(:view_pii)).not_to contain_exactly(facility_1, facility_3, facility_4, facility_5)
        end
      end

      context "manage action" do
        it "returns all facilities the manager can manage" do
          expect(manager.accesses.facilities(:manage)).to contain_exactly(facility_1, facility_3, facility_5)
          expect(manager.accesses.facilities(:manage)).not_to contain_exactly(facility_2, facility_4, facility_6)
        end

        it "returns all facilities the viewer_all can manage" do
          expect(viewer_all.accesses.facilities(:manage)).to be_empty
        end
      end
    end
  end
end
