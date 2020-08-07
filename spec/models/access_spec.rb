require "rails_helper"

RSpec.describe Access, type: :model do
  describe "Associations" do
    it { is_expected.to belong_to(:user) }
    pending { is_expected.to belong_to(:resource).optional }
  end

  describe "Validations" do
    it { is_expected.to validate_presence_of(:role) }

    it {
      is_expected.to define_enum_for(:role)
        .with_values(super_admin: "super_admin",
                     manager: "manager",
                     health_care_worker: "health_care_worker",
                     health_administrator: "health_administrator",
                     call_center_worker: "call_center_worker")
        .backed_by_column_of_type(:string)
    }

    it "does not allow creating accesses for user with multiple roles" do
      admin = create(:admin)
      valid_access_1 = create(:access, role: :manager, user: admin, resource: create(:facility))
      valid_access_2 = build(:access, role: :manager, user: admin, resource: create(:facility_group))
      invalid_access = build(:access, role: :health_care_worker, user: admin, resource: create(:facility))

      expect(valid_access_1).to be_valid
      expect(valid_access_2).to be_valid
      expect(invalid_access).to be_invalid
    end

    context "resource" do
      let(:admin) { create(:admin) }
      let!(:resource) { create(:facility) }

      it "is invalid if user has more than one access per resource" do
        __valid_access = create(:access, :health_care_worker, user: admin, resource: resource)
        invalid_access = build(:access, :health_care_worker, user: admin, resource: resource)

        expect(invalid_access).to be_invalid
        expect(invalid_access.errors.messages[:user]).to eq ["can only have one access per resource."]
      end

      it "is invalid if non super-admins don't have a resource" do
        invalid_access = build(:access, :health_care_worker, user: admin, resource: nil)

        expect(invalid_access).to be_invalid
        expect(invalid_access.errors.messages[:resource]).to eq ["is required if not a super_admin."]
      end

      it "is invalid if super_admin has a resource" do
        invalid_access = build(:access, :super_admin, user: admin, resource: create(:facility))

        expect(invalid_access).to be_invalid
        expect(invalid_access.errors.messages[:resource]).to eq ["must be nil if super_admin"]
      end

      it "is invalid if resource_type is not in the allow-list" do
        valid_access_1 = build(:access, :health_care_worker, user: admin, resource: create(:organization))
        valid_access_2 = build(:access, :health_care_worker, user: admin, resource: create(:facility_group))
        valid_access_3 = build(:access, :health_care_worker, user: admin, resource: create(:facility))
        invalid_access = build(:access, :health_care_worker, user: admin, resource: create(:appointment))

        expect(valid_access_1).to be_valid
        expect(valid_access_2).to be_valid
        expect(valid_access_3).to be_valid
        expect(invalid_access).to be_invalid
        expect(invalid_access.errors.messages[:resource_type]).to eq ["is not included in the list"]
      end
    end
  end

  describe ".can?" do
    let(:health_care_worker) { create(:admin) }
    let(:manager) { create(:admin) }
    let(:super_admin) do
      user = create(:admin)
      create(:access, :super_admin, user: user)
      user
    end

    context "organizations" do
      let!(:organization_1) { create(:organization) }
      let!(:organization_2) { create(:organization) }
      let!(:organization_3) { create(:organization) }

      context "view action" do
        it "allows super admin to view anything" do
          expect(super_admin.can?(:view_pii, :organization, organization_1)).to be true
          expect(super_admin.can?(:view_pii, :organization, organization_2)).to be true
          expect(super_admin.can?(:view_pii, :organization, organization_3)).to be true
          expect(super_admin.can?(:view_pii, :organization)).to be true
        end

        it "allows manager to view" do
          create(:access, :manager, user: manager, resource: organization_1)

          expect(manager.can?(:view_pii, :organization, organization_1)).to be true
          expect(manager.can?(:view_pii, :organization, organization_2)).to be false
          expect(manager.can?(:view_pii, :organization, organization_3)).to be false
          expect(manager.can?(:view_pii, :organization)).to be true
        end

        it "allows health_care_worker to view" do
          create(:access, :health_care_worker, user: health_care_worker, resource: organization_3)

          expect(health_care_worker.can?(:view_pii, :organization, organization_1)).to be false
          expect(health_care_worker.can?(:view_pii, :organization, organization_2)).to be false
          expect(health_care_worker.can?(:view_pii, :organization, organization_3)).to be true
          expect(health_care_worker.can?(:view_pii, :organization)).to be true
        end
      end

      context "manage action" do
        it "allows super admin to manage anything" do
          expect(super_admin.can?(:manage, :organization, organization_1)).to be true
          expect(super_admin.can?(:manage, :organization, organization_2)).to be true
          expect(super_admin.can?(:manage, :organization, organization_3)).to be true
          expect(super_admin.can?(:manage, :organization)).to be true
        end

        it "allows manager to manage" do
          create(:access, :manager, user: manager, resource: organization_1)

          expect(manager.can?(:manage, :organization, organization_1)).to be true
          expect(manager.can?(:manage, :organization, organization_2)).to be false
          expect(manager.can?(:manage, :organization, organization_3)).to be false
          expect(manager.can?(:manage, :organization)).to be true
        end

        it "allows health_care_worker to manage" do
          create(:access, :health_care_worker, user: health_care_worker, resource: organization_3)

          expect(health_care_worker.can?(:manage, :organization, organization_1)).to be false
          expect(health_care_worker.can?(:manage, :organization, organization_2)).to be false
          expect(health_care_worker.can?(:manage, :organization, organization_3)).to be false
          expect(health_care_worker.can?(:manage, :organization)).to be false
        end
      end
    end

    context "facility_groups" do
      let!(:facility_group_1) { create(:facility_group) }
      let!(:facility_group_2) { create(:facility_group) }
      let!(:facility_group_3) { create(:facility_group) }

      context "view action" do
        it "allows super admin to view anything" do
          expect(super_admin.can?(:view_pii, :facility_group, facility_group_1)).to be true
          expect(super_admin.can?(:view_pii, :facility_group, facility_group_2)).to be true
          expect(super_admin.can?(:view_pii, :facility_group, facility_group_3)).to be true
          expect(super_admin.can?(:view_pii, :facility_group)).to be true
        end

        it "allows manager to view" do
          create(:access, :manager, user: manager, resource: facility_group_1)

          expect(manager.can?(:view_pii, :facility_group, facility_group_1)).to be true
          expect(manager.can?(:view_pii, :facility_group, facility_group_2)).to be false
          expect(manager.can?(:view_pii, :facility_group, facility_group_3)).to be false
          expect(manager.can?(:view_pii, :facility_group)).to be true
        end

        it "allows health_care_worker to view" do
          create(:access, :health_care_worker, user: health_care_worker, resource: facility_group_3)

          expect(health_care_worker.can?(:view_pii, :facility_group, facility_group_1)).to be false
          expect(health_care_worker.can?(:view_pii, :facility_group, facility_group_2)).to be false
          expect(health_care_worker.can?(:view_pii, :facility_group, facility_group_3)).to be true
          expect(health_care_worker.can?(:view_pii, :facility_group)).to be true
        end
      end

      context "manage action" do
        it "allows super admin to manage anything" do
          expect(super_admin.can?(:manage, :facility_group, facility_group_1)).to be true
          expect(super_admin.can?(:manage, :facility_group, facility_group_2)).to be true
          expect(super_admin.can?(:manage, :facility_group, facility_group_3)).to be true
          expect(super_admin.can?(:manage, :facility_group)).to be true
        end

        it "allows manager to manage" do
          create(:access, :manager, user: manager, resource: facility_group_1)

          expect(manager.can?(:manage, :facility_group, facility_group_1)).to be true
          expect(manager.can?(:manage, :facility_group, facility_group_2)).to be false
          expect(manager.can?(:manage, :facility_group, facility_group_3)).to be false
          expect(manager.can?(:manage, :facility_group)).to be true
        end

        it "allows health_care_worker to manage" do
          create(:access, :health_care_worker, user: health_care_worker, resource: facility_group_3)

          expect(health_care_worker.can?(:manage, :facility_group, facility_group_1)).to be false
          expect(health_care_worker.can?(:manage, :facility_group, facility_group_2)).to be false
          expect(health_care_worker.can?(:manage, :facility_group, facility_group_3)).to be false
          expect(health_care_worker.can?(:manage, :facility_group)).to be false
        end
      end

      context "when org-level access" do
        let!(:organization_1) { create(:organization) }
        let!(:facility_group_1) { create(:facility_group, organization: organization_1) }
        let!(:facility_group_2) { create(:facility_group) }
        let!(:facility_group_3) { create(:facility_group) }

        it "allows manager to view" do
          create(:access, :manager, user: manager, resource: organization_1)
          create(:access, :manager, user: manager, resource: facility_group_2)

          expect(manager.can?(:view_pii, :facility_group, facility_group_1)).to be true
          expect(manager.can?(:view_pii, :facility_group, facility_group_2)).to be true
          expect(manager.can?(:view_pii, :facility_group, facility_group_3)).to be false
          expect(manager.can?(:view_pii, :facility_group)).to be true
        end

        it "allows health_care_worker to view" do
          create(:access, :health_care_worker, user: health_care_worker, resource: organization_1)
          create(:access, :health_care_worker, user: health_care_worker, resource: facility_group_2)

          expect(health_care_worker.can?(:view_pii, :facility_group, facility_group_1)).to be true
          expect(health_care_worker.can?(:view_pii, :facility_group, facility_group_2)).to be true
          expect(health_care_worker.can?(:view_pii, :facility_group, facility_group_3)).to be false
          expect(health_care_worker.can?(:view_pii, :facility_group)).to be true
        end

        it "does not allow health_care_worker to manage" do
          create(:access, :health_care_worker, user: health_care_worker, resource: organization_1)
          create(:access, :health_care_worker, user: health_care_worker, resource: facility_group_2)

          expect(health_care_worker.can?(:manage, :facility_group, facility_group_1)).to be false
          expect(health_care_worker.can?(:manage, :facility_group, facility_group_2)).to be false
          expect(health_care_worker.can?(:manage, :facility_group, facility_group_3)).to be false
          expect(health_care_worker.can?(:manage, :facility_group)).to be false
        end

        it "allows manager to manage" do
          create(:access, :manager, user: manager, resource: organization_1)
          create(:access, :manager, user: manager, resource: facility_group_2)

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
        it "allows super admin to view anything" do
          expect(super_admin.can?(:view_pii, :facility, facility_1)).to be true
          expect(super_admin.can?(:view_pii, :facility, facility_2)).to be true
          expect(super_admin.can?(:view_pii, :facility, facility_3)).to be true
          expect(super_admin.can?(:view_pii, :facility)).to be true
        end

        it "allows manager to view" do
          create(:access, :manager, user: manager, resource: facility_1)

          expect(manager.can?(:view_pii, :facility, facility_1)).to be true
          expect(manager.can?(:view_pii, :facility, facility_2)).to be false
          expect(manager.can?(:view_pii, :facility, facility_3)).to be false
          expect(manager.can?(:view_pii, :facility)).to be true
        end

        it "allows health_care_worker to view" do
          create(:access, :health_care_worker, user: health_care_worker, resource: facility_3)

          expect(health_care_worker.can?(:view_pii, :facility, facility_1)).to be false
          expect(health_care_worker.can?(:view_pii, :facility, facility_2)).to be false
          expect(health_care_worker.can?(:view_pii, :facility, facility_3)).to be true
          expect(health_care_worker.can?(:view_pii, :facility)).to be true
        end
      end

      context "manage action" do
        it "allows super admin to manage anything" do
          expect(super_admin.can?(:manage, :facility, facility_1)).to be true
          expect(super_admin.can?(:manage, :facility, facility_2)).to be true
          expect(super_admin.can?(:manage, :facility, facility_3)).to be true
          expect(super_admin.can?(:manage, :facility)).to be true
        end

        it "allows manager to manage" do
          create(:access, :manager, user: manager, resource: facility_1)

          expect(manager.can?(:manage, :facility, facility_1)).to be true
          expect(manager.can?(:manage, :facility, facility_2)).to be false
          expect(manager.can?(:manage, :facility, facility_3)).to be false
          expect(manager.can?(:manage, :facility)).to be true
        end

        it "allows health_care_worker to manage" do
          create(:access, :health_care_worker, user: health_care_worker, resource: facility_3)

          expect(health_care_worker.can?(:manage, :facility, facility_1)).to be false
          expect(health_care_worker.can?(:manage, :facility, facility_2)).to be false
          expect(health_care_worker.can?(:manage, :facility, facility_3)).to be false
          expect(health_care_worker.can?(:manage, :facility)).to be false
        end
      end

      context "when facility-group-level access" do
        let!(:facility_group_1) { create(:facility_group) }
        let!(:facility_1) { create(:facility, facility_group: facility_group_1) }
        let!(:facility_2) { create(:facility) }
        let!(:facility_3) { create(:facility) }

        it "allows manager to view" do
          create(:access, :manager, user: manager, resource: facility_group_1)
          create(:access, :manager, user: manager, resource: facility_2)

          expect(manager.can?(:view_pii, :facility, facility_1)).to be true
          expect(manager.can?(:view_pii, :facility, facility_2)).to be true
          expect(manager.can?(:view_pii, :facility, facility_3)).to be false
          expect(manager.can?(:view_pii, :facility)).to be true
        end

        it "allows health_care_worker to view" do
          create(:access, :health_care_worker, user: health_care_worker, resource: facility_group_1)
          create(:access, :health_care_worker, user: health_care_worker, resource: facility_2)

          expect(health_care_worker.can?(:view_pii, :facility, facility_1)).to be true
          expect(health_care_worker.can?(:view_pii, :facility, facility_2)).to be true
          expect(health_care_worker.can?(:view_pii, :facility, facility_3)).to be false
          expect(health_care_worker.can?(:view_pii, :facility)).to be true
        end

        it "does not allow health_care_worker to manage" do
          create(:access, :health_care_worker, user: health_care_worker, resource: facility_group_1)
          create(:access, :health_care_worker, user: health_care_worker, resource: facility_2)

          expect(health_care_worker.can?(:manage, :facility, facility_1)).to be false
          expect(health_care_worker.can?(:manage, :facility, facility_2)).to be false
          expect(health_care_worker.can?(:manage, :facility, facility_3)).to be false
          expect(health_care_worker.can?(:manage, :facility)).to be false
        end

        it "allows manager to manage" do
          create(:access, :manager, user: manager, resource: facility_group_1)
          create(:access, :manager, user: manager, resource: facility_2)

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
          create(:access, :manager, user: manager, resource: organization_1)
          create(:access, :manager, user: manager, resource: facility_2)

          expect(manager.can?(:view_pii, :facility, facility_1)).to be true
          expect(manager.can?(:view_pii, :facility, facility_2)).to be true
          expect(manager.can?(:view_pii, :facility, facility_3)).to be false
          expect(manager.can?(:view_pii, :facility)).to be true
        end

        it "allows health_care_worker to view" do
          create(:access, :health_care_worker, user: health_care_worker, resource: organization_1)
          create(:access, :health_care_worker, user: health_care_worker, resource: facility_2)

          expect(health_care_worker.can?(:view_pii, :facility, facility_1)).to be true
          expect(health_care_worker.can?(:view_pii, :facility, facility_2)).to be true
          expect(health_care_worker.can?(:view_pii, :facility, facility_3)).to be false
          expect(health_care_worker.can?(:view_pii, :facility)).to be true
        end

        it "does not allow health_care_worker to manage" do
          create(:access, :health_care_worker, user: health_care_worker, resource: organization_1)
          create(:access, :health_care_worker, user: health_care_worker, resource: facility_2)

          expect(health_care_worker.can?(:manage, :facility, facility_1)).to be false
          expect(health_care_worker.can?(:manage, :facility, facility_2)).to be false
          expect(health_care_worker.can?(:manage, :facility, facility_3)).to be false
          expect(health_care_worker.can?(:manage, :facility)).to be false
        end

        it "allows manager to manage" do
          create(:access, :manager, user: manager, resource: organization_1)
          create(:access, :manager, user: manager, resource: facility_2)

          expect(manager.can?(:manage, :facility, facility_1)).to be true
          expect(manager.can?(:manage, :facility, facility_2)).to be true
          expect(manager.can?(:manage, :facility, facility_3)).to be false
          expect(manager.can?(:manage, :facility)).to be true
        end
      end
    end
  end

  describe ".organizations" do
    let(:health_care_worker) { create(:admin) }
    let(:manager) { create(:admin) }
    let!(:organization_1) { create(:organization) }
    let!(:organization_2) { create(:organization) }
    let!(:organization_3) { create(:organization) }
    let!(:manager_access) { create(:access, :manager, user: manager, resource: organization_1) }
    let!(:health_care_worker_access) { create(:access, :health_care_worker, user: health_care_worker, resource: organization_2) }

    context "view action" do
      it "returns all organizations the manager can view" do
        expect(manager.accesses.organizations(:view_pii)).to contain_exactly(organization_1)
        expect(manager.accesses.organizations(:view_pii)).not_to contain_exactly(organization_2)
      end

      it "returns all organizations the health_care_worker can view" do
        expect(health_care_worker.accesses.organizations(:view_pii)).to contain_exactly(organization_2)
        expect(health_care_worker.accesses.organizations(:view_pii)).not_to contain_exactly(organization_1)
      end
    end

    context "manage action" do
      it "returns all organizations the manager can manage" do
        expect(manager.accesses.organizations(:manage)).to contain_exactly(organization_1)
        expect(manager.accesses.organizations(:manage)).not_to contain_exactly(organization_2)
      end

      it "returns all organizations the health_care_worker can manage" do
        expect(health_care_worker.accesses.organizations(:manage)).to be_empty
      end
    end
  end

  describe ".facility_groups" do
    let(:health_care_worker) { create(:admin) }
    let(:manager) { create(:admin) }

    context "for a direct facility-group-level access" do
      let!(:facility_group_1) { create(:facility_group) }
      let!(:facility_group_2) { create(:facility_group) }
      let!(:facility_group_3) { create(:facility_group) }
      let!(:manager_access) { create(:access, :manager, user: manager, resource: facility_group_1) }
      let!(:health_care_worker_access) { create(:access, :health_care_worker, user: health_care_worker, resource: facility_group_2) }

      context "view action" do
        it "returns all facility_groups the manager can view" do
          expect(manager.accesses.facility_groups(:view_pii)).to contain_exactly(facility_group_1)
          expect(manager.accesses.facility_groups(:view_pii)).not_to contain_exactly(facility_group_2, facility_group_3)
        end

        it "returns all facility_groups the health_care_worker can view" do
          expect(health_care_worker.accesses.facility_groups(:view_pii)).to contain_exactly(facility_group_2)
          expect(health_care_worker.accesses.facility_groups(:view_pii)).not_to contain_exactly(facility_group_1, facility_group_3)
        end
      end

      context "manage action" do
        it "returns all facility_groups the manager can manage" do
          expect(manager.accesses.facility_groups(:manage)).to contain_exactly(facility_group_1)
          expect(manager.accesses.facility_groups(:manage)).not_to contain_exactly(facility_group_2, facility_group_3)
        end

        it "returns all facility_groups the health_care_worker can manage" do
          expect(health_care_worker.accesses.facility_groups(:manage)).to be_empty
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

      let!(:org_manager_access) { create(:access, :manager, user: manager, resource: organization_1) }
      let!(:fg_manager_access) { create(:access, :manager, user: manager, resource: facility_group_3) }

      let!(:org_health_care_worker_access) { create(:access, :health_care_worker, user: health_care_worker, resource: organization_2) }
      let!(:fg_health_care_worker_access) { create(:access, :health_care_worker, user: health_care_worker, resource: facility_group_4) }

      context "view action" do
        it "returns all facilities the manager can view" do
          expect(manager.accesses.facility_groups(:view_pii)).to contain_exactly(facility_group_1, facility_group_3)
          expect(manager.accesses.facility_groups(:view_pii)).not_to contain_exactly(facility_group_2, facility_group_4)
        end

        it "returns all facility_groups the health_care_worker can view" do
          expect(health_care_worker.accesses.facility_groups(:view_pii)).to contain_exactly(facility_group_2, facility_group_4)
          expect(health_care_worker.accesses.facility_groups(:view_pii)).not_to contain_exactly(facility_group_1, facility_group_3)
        end
      end

      context "manage action" do
        it "returns all facility_groups the manager can manage" do
          expect(manager.accesses.facility_groups(:manage)).to contain_exactly(facility_group_1, facility_group_3)
          expect(manager.accesses.facility_groups(:manage)).not_to contain_exactly(facility_group_2, facility_group_4)
        end

        it "returns all facility_groups the health_care_worker can manage" do
          expect(health_care_worker.accesses.facility_groups(:manage)).to be_empty
        end
      end
    end
  end

  describe ".facilities" do
    let(:health_care_worker) { create(:admin) }
    let(:manager) { create(:admin) }

    context "for a direct facility-level access" do
      let!(:facility_1) { create(:facility) }
      let!(:facility_2) { create(:facility) }
      let!(:facility_3) { create(:facility) }
      let!(:manager_access) { create(:access, :manager, user: manager, resource: facility_1) }
      let!(:health_care_worker_access) { create(:access, :health_care_worker, user: health_care_worker, resource: facility_2) }

      context "view action" do
        it "returns all facilities the manager can view" do
          expect(manager.accesses.facilities(:view_pii)).to contain_exactly(facility_1)
          expect(manager.accesses.facilities(:view_pii)).not_to contain_exactly(facility_2, facility_3)
        end

        it "returns all facilities the health_care_worker can view" do
          expect(health_care_worker.accesses.facilities(:view_pii)).to contain_exactly(facility_2)
          expect(health_care_worker.accesses.facilities(:view_pii)).not_to contain_exactly(facility_1, facility_3)
        end
      end

      context "manage action" do
        it "returns all facilities the manager can manage" do
          expect(manager.accesses.facilities(:manage)).to contain_exactly(facility_1)
          expect(manager.accesses.facilities(:manage)).not_to contain_exactly(facility_2, facility_3)
        end

        it "returns all facilities the health_care_worker can manage" do
          expect(health_care_worker.accesses.facilities(:manage)).to be_empty
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

      let!(:health_care_worker_access) { create(:access, :health_care_worker, user: health_care_worker, resource: facility_group_2) }
      let!(:facility_health_care_worker_access) { create(:access, :health_care_worker, user: health_care_worker, resource: facility_5) }

      context "view action" do
        it "returns all facilities the manager can view" do
          expect(manager.accesses.facilities(:view_pii)).to contain_exactly(facility_1, facility_4)
          expect(manager.accesses.facilities(:view_pii)).not_to contain_exactly(facility_2, facility_3, facility_5, facility_6)
        end

        it "returns all facilities the health_care_worker can view" do
          expect(health_care_worker.accesses.facilities(:view_pii)).to contain_exactly(facility_2, facility_5)
          expect(health_care_worker.accesses.facilities(:view_pii)).not_to contain_exactly(facility_1, facility_3, facility_4, facility_6)
        end
      end

      context "manage action" do
        it "returns all facilities the manager can manage" do
          expect(manager.accesses.facilities(:manage)).to contain_exactly(facility_1, facility_4)
          expect(manager.accesses.facilities(:manage)).not_to contain_exactly(facility_2, facility_3, facility_5, facility_6)
        end

        it "returns all facilities the health_care_worker can manage" do
          expect(health_care_worker.accesses.facilities(:manage)).to be_empty
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

      let!(:health_care_worker_access) { create(:access, :health_care_worker, user: health_care_worker, resource: organization_2) }
      let!(:facility_health_care_worker_access) { create(:access, :health_care_worker, user: health_care_worker, resource: facility_6) }

      context "view action" do
        it "returns all facilities the manager can view" do
          expect(manager.accesses.facilities(:view_pii)).to contain_exactly(facility_1, facility_3, facility_5)
          expect(manager.accesses.facilities(:view_pii)).not_to contain_exactly(facility_2, facility_4, facility_6)
        end

        it "returns all facilities the health_care_worker can view" do
          expect(health_care_worker.accesses.facilities(:view_pii)).to contain_exactly(facility_2, facility_6)
          expect(health_care_worker.accesses.facilities(:view_pii)).not_to contain_exactly(facility_1, facility_3, facility_4, facility_5)
        end
      end

      context "manage action" do
        it "returns all facilities the manager can manage" do
          expect(manager.accesses.facilities(:manage)).to contain_exactly(facility_1, facility_3, facility_5)
          expect(manager.accesses.facilities(:manage)).not_to contain_exactly(facility_2, facility_4, facility_6)
        end

        it "returns all facilities the health_care_worker can manage" do
          expect(health_care_worker.accesses.facilities(:manage)).to be_empty
        end
      end
    end
  end
end
