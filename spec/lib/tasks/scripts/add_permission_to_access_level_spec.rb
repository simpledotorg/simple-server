require "rails_helper"
require "tasks/scripts/add_permission_to_access_level"

RSpec.describe AddPermissionToAccessLevel do
  describe "#valid?" do
    it "validates that the permission exists" do
      expect(described_class.new(:fake_permission, :owner).valid?).to eq(false)
      expect(described_class.new(:manage_organizations, :owner).valid?).to eq(true)
    end

    it "validates that the permission is present in the defaults for the role" do
      expect(described_class.new(:manage_organizations, :supervisor).valid?).to eq(false)
      expect(described_class.new(:manage_organizations, :owner).valid?).to eq(true)
    end
  end

  describe "#create" do
    let!(:organization) { create(:organization) }
    let!(:facility_group_1) { create(:facility_group, organization: organization) }
    let!(:facility_group_2) { create(:facility_group, organization: organization) }
    let!(:owner) { create(:admin, :owner) }
    let!(:organization_owner) { create(:admin, :organization_owner, organization: organization) }
    let!(:supervisor_1) { create(:admin, :supervisor, facility_group: facility_group_1) }
    let!(:supervisor_2) { create(:admin, :supervisor, facility_group: facility_group_2) }
    let!(:access_levels) { Permissions::ACCESS_LEVELS }
    let!(:all_permissions) { Permissions::ALL_PERMISSIONS }

    before do
      create(:user_permission, user: supervisor_1, permission_slug: :manage_facilities, resource_type: "FacilityGroup", resource_id: facility_group_2.id)
      allow(Rails.logger).to receive(:info).and_return nil
    end

    context "users have permissions" do
      it "doesn't create permissions for users who already have them" do
        expect { described_class.new(:view_cohort_reports, :supervisor).create }.not_to change { UserPermission.count }
      end
    end

    context "users don't have permissions" do
      it "creates multiple permissions for users who have permissions at multiple resources" do
        UserPermission.where(user: supervisor_1, permission_slug: "view_cohort_reports").each(&:destroy!)

        expect(Rails.logger).to receive(:info)
          .with("Creating a 'view_cohort_reports' permission for User: #{supervisor_1.full_name} (#{supervisor_1.id}),"\
                " with Resource type: 'FacilityGroup' and Resource id: #{facility_group_1.id}")

        expect(Rails.logger).to receive(:info)
          .with("Creating a 'view_cohort_reports' permission for User: #{supervisor_1.full_name} (#{supervisor_1.id}),"\
                " with Resource type: 'FacilityGroup' and Resource id: #{facility_group_2.id}")

        described_class.new(:view_cohort_reports, :supervisor).create

        expect(UserPermission.exists?(user_id: supervisor_1.id,
                                      permission_slug: "view_cohort_reports",
                                      resource_id: facility_group_1.id,
                                      resource_type: "FacilityGroup"))
          .to eq(true)
        expect(UserPermission.exists?(user_id: supervisor_1.id,
                                      permission_slug: "view_cohort_reports",
                                      resource_id: facility_group_2.id,
                                      resource_type: "FacilityGroup"))
          .to eq(true)
      end

      it "creates only one permission for users who have permission at a single resource" do
        UserPermission.where(user: supervisor_2, permission_slug: "view_cohort_reports").each(&:destroy!)

        described_class.new(:view_cohort_reports, :supervisor).create

        expect(UserPermission.exists?(user_id: supervisor_2.id,
                                      permission_slug: "view_cohort_reports",
                                      resource_id: facility_group_1.id,
                                      resource_type: "FacilityGroup"))
          .to eq(false)
        expect(UserPermission.exists?(user_id: supervisor_2.id,
                                      permission_slug: "view_cohort_reports",
                                      resource_id: facility_group_2.id,
                                      resource_type: "FacilityGroup"))
          .to eq(true)
      end
    end

    context "resource priorities" do
      context "permissions which only have a global priority" do
        before do
          UserPermission.where(permission_slug: "view_my_facilities").each(&:destroy!)
        end

        it "creates a permission of resource_type `nil` (global) even if the user has no other permissions of that type" do
          stub_const("Permissions::ACCESS_LEVELS", [{name: :supervisor,
                                                     description: "CVHO: Cardiovascular Health Officer",
                                                     default_permissions: %i[manage_facilities
                                                       view_overdue_list
                                                       download_overdue_list
                                                       approve_health_workers
                                                       view_cohort_reports
                                                       view_health_worker_activity
                                                       download_patient_line_list
                                                       manage_admins
                                                       view_my_facilities]}])

          expect(Rails.logger).to receive(:info).with("Creating a global 'view_my_facilities' permission for User: "\
                                                      "#{supervisor_1.full_name} (#{supervisor_1.id})")
          expect(Rails.logger).to receive(:info).with("Creating a global 'view_my_facilities' permission for User: "\
                                                      "#{supervisor_2.full_name} (#{supervisor_2.id})")

          described_class.new(:view_my_facilities, :supervisor).create

          expect(UserPermission.exists?(user: supervisor_1,
                                        permission_slug: "view_my_facilities",
                                        resource_id: nil,
                                        resource_type: nil))
            .to eq(true)

          expect(UserPermission.exists?(user: supervisor_2,
                                        permission_slug: "view_my_facilities",
                                        resource_id: nil,
                                        resource_type: nil))
            .to eq(true)
        end
      end

      context "permissions which have multiple priorities" do
        before do
          UserPermission.where(permission_slug: "view_cohort_reports").each(&:destroy!)
        end

        it "creates a permission with the lowest priority resource_type when the user has other permissions of that type, "\
           "even if the user has permissions with higher priority resource_types" do
          UserPermission.find_by(user: supervisor_1,
                                 permission_slug: "manage_admins")
            .update(resource_id: organization.id,
                    resource_type: "Organization")

          expect(Rails.logger).to receive(:info)
            .with("Creating a 'view_cohort_reports' permission for User: #{supervisor_1.full_name} (#{supervisor_1.id}),"\
                  " with Resource type: 'FacilityGroup' and Resource id: #{facility_group_1.id}")

          expect(Rails.logger).to receive(:info)
            .with("Creating a 'view_cohort_reports' permission for User: #{supervisor_2.full_name} (#{supervisor_2.id}),"\
                  " with Resource type: 'FacilityGroup' and Resource id: #{facility_group_2.id}")

          described_class.new(:view_cohort_reports, :supervisor).create

          expect(UserPermission.exists?(user: supervisor_1,
                                        permission_slug: "view_cohort_reports",
                                        resource_id: [facility_group_1.id, facility_group_2.id],
                                        resource_type: "FacilityGroup"))
            .to eq(true)

          expect(UserPermission.exists?(user: supervisor_1,
                                        permission_slug: "view_cohort_reports",
                                        resource_type: "Organization"))
            .to eq(false)

          expect(UserPermission.exists?(user: supervisor_2,
                                        permission_slug: "view_cohort_reports",
                                        resource_id: facility_group_2.id,
                                        resource_type: "FacilityGroup"))
            .to eq(true)
        end

        it "creates a permission of resource_type 'Organization' when the user has other permissions of that type" do
          expect(Rails.logger).to receive(:info)
            .with("Creating a 'view_cohort_reports' permission for User: #{organization_owner.full_name} "\
          "(#{organization_owner.id}), with Resource type: 'Organization' and Resource id: #{organization.id}")

          described_class.new(:view_cohort_reports, :organization_owner).create

          expect(UserPermission.exists?(user: organization_owner,
                                        permission_slug: "view_cohort_reports",
                                        resource_id: organization.id,
                                        resource_type: "Organization"))
            .to eq(true)
        end

        it "creates a permission of resource_type `nil` (global) when the user has other permissions of that type" do
          expect(Rails.logger).to receive(:info).with("Creating a global 'view_cohort_reports' permission for User: "\
                                                      "#{owner.full_name} (#{owner.id})")
          described_class.new(:view_cohort_reports, :owner).create

          expect(UserPermission.exists?(user: owner,
                                        permission_slug: "view_cohort_reports",
                                        resource_id: nil,
                                        resource_type: nil))
            .to eq(true)
        end
      end
    end
  end
end
