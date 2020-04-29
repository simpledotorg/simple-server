require 'rails_helper'
require 'tasks/scripts/add_permission_to_access_level'

RSpec.describe AddPermissionToAccessLevel do
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
    create(:user_permission, user: supervisor_1, permission_slug: :manage_facilities, resource_type: 'FacilityGroup', resource_id: facility_group_2.id)
  end

  describe '#valid?' do
    it 'validates that the permission exists' do
      expect(described_class.new(:fake_permission, :owner).valid?).to be_falsey
      expect(described_class.new(:manage_organizations, :owner).valid?).to be_truthy
    end

    it 'validates that the permission is present in the defaults for the role' do
      expect(described_class.new(:manage_organizations, :supervisor).valid?).to be_falsey
      expect(described_class.new(:manage_organizations, :owner).valid?).to be_truthy
    end
  end

  describe '#create' do
    it "doesn't create permissions for users who already have them" do
      expect { described_class.new(:view_cohort_reports, :supervisor).create }.not_to change { UserPermission.count }
    end

    it "creates permissions for users who don't have them" do
      UserPermission.where(user_id: supervisor_1.id, permission_slug: 'view_cohort_reports').each(&:delete)

      expect { described_class.new(:view_cohort_reports, :supervisor).create }
        .to change { UserPermission.where(user_id: supervisor_1.id, permission_slug: 'view_cohort_reports', user: [supervisor_1]).count }.by(2)
    end

    it 'creates permissions of the appropriate resource_priority' do
      UserPermission.where(permission_slug: 'view_cohort_reports').each(&:delete)

      expect { described_class.new(:view_cohort_reports, :supervisor).create }
        .to change { UserPermission.where(permission_slug: 'view_cohort_reports', resource_type: 'FacilityGroup', user: [supervisor_1, supervisor_2]).count }.by(3)

      expect { described_class.new(:view_cohort_reports, :organization_owner).create }
        .to change { UserPermission.where(permission_slug: 'view_cohort_reports', resource_type: 'Organization', user: organization_owner).count }.by(1)

      expect { described_class.new(:view_cohort_reports, :owner).create }
        .to change { UserPermission.where(permission_slug: 'view_cohort_reports', resource_type: nil, user: owner).count }.by(1)
    end
  end
end
