require "rails_helper"

RSpec.describe Upcoming::Manage::FacilityGroupPolicy do
  subject { described_class }

  context "user can manage all facility_groups" do
    let!(:super_admin) { create(:admin) }

    let!(:facility_group_1) { create(:facility_group) }
    let!(:facility_group_2) { create(:facility_group) }
    let!(:super_admin_access) { create(:access, user: super_admin, role: :super_admin, resource: nil) }

    permissions :allowed? do
      it "allows the user" do
        expect(subject).to permit(super_admin, facility_group_1)
        expect(subject).to permit(super_admin, facility_group_2)
      end
    end
  end

  context "user can manage facility_groups for an organization" do
    let!(:organization) { create(:organization) }
    let!(:admin) { create(:admin) }

    let!(:admin_access) { create(:access, user: admin, role: :admin, resource: organization) }

    let!(:facility_group_1) { create(:facility_group, organization: organization) }
    let!(:facility_group_2) { create(:facility_group) }

    permissions :allowed? do
      it "allows the user" do
        expect(subject).to permit(admin, facility_group_1)
      end

      it "denies the user" do
        expect(subject).not_to permit(admin, facility_group_2)
      end
    end
  end

  context "user can manage a single facility_group" do
    let!(:admin) { create(:admin) }

    let!(:facility_group_1) { create(:facility_group) }
    let!(:facility_group_2) { create(:facility_group) }

    let!(:admin_access) { create(:access, user: admin, role: :admin, resource: facility_group_1) }

    permissions :allowed? do
      it "allows the user" do
        expect(subject).to permit(admin, facility_group_1)
      end

      it "denies the user" do
        expect(subject).not_to permit(admin, facility_group_2)
      end
    end
  end
end

RSpec.describe Upcoming::Manage::FacilityGroupPolicy::Scope do
  let(:subject) { described_class }
  let(:organization) { create(:organization) }
  let!(:facility_group_1) { create(:facility_group, organization: organization) }
  let!(:facility_group_2) { create(:facility_group, organization: organization) }
  let!(:facility_group_3) { create(:facility_group) }

  context "user can manage all facility groups" do
    let!(:super_admin) { create(:admin) }
    let!(:super_admin_access) { create(:access, user: super_admin, role: :super_admin, resource: nil) }

    it "resolve all facility groups" do
      resolved_records = subject.new(super_admin, FacilityGroup).resolve
      expect(resolved_records).to include(facility_group_1, facility_group_2, facility_group_3)
    end
  end

  context "user can manage facility groups for an organization" do
    let!(:admin) { create(:admin) }
    let!(:admin_access) { create(:access, user: admin, role: :admin, resource: organization) }

    it "resolves all facility groups in their organization" do
      resolved_records = subject.new(admin, FacilityGroup).resolve
      expect(resolved_records).to include(facility_group_1, facility_group_2)
      expect(resolved_records).not_to include(facility_group_3)
    end
  end

  context "other users" do
    let(:other_user) { create(:admin) }

    it "resolves an empty set" do
      resolved_records = subject.new(other_user, FacilityGroup.all).resolve
      expect(resolved_records).to be_empty
    end
  end
end
