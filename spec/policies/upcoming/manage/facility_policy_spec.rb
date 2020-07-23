require "rails_helper"

RSpec.describe Upcoming::Manage::FacilityPolicy do
  subject { described_class }

  context "user can manage all facility_groups" do
    let!(:super_admin) { create(:admin) }

    let!(:facility_1) { create(:facility) }
    let!(:facility_2) { create(:facility) }
    let!(:super_admin_access) { create(:access, user: super_admin, role: :super_admin, resource: nil) }

    permissions :allowed? do
      it "allows the user" do
        expect(subject).to permit(super_admin, facility_1)
        expect(subject).to permit(super_admin, facility_2)
      end
    end
  end

  context "user can manage facilities for an organization" do
    let!(:organization) { create(:organization) }
    let!(:facility_group) { create(:facility_group, organization: organization) }
    let!(:admin) { create(:admin) }

    let!(:admin_access) { create(:access, user: admin, role: :admin, resource: organization) }

    let!(:facility_1) { create(:facility, facility_group: facility_group) }
    let!(:facility_2) { create(:facility) }

    permissions :allowed? do
      it "allows the user" do
        expect(subject).to permit(admin, facility_1)
      end

      it "denies the user" do
        expect(subject).not_to permit(admin, facility_2)
      end
    end
  end

  context "user can manage a single facility" do
    let!(:admin) { create(:admin) }

    let!(:facility_1) { create(:facility) }
    let!(:facility_2) { create(:facility) }

    let!(:admin_access) { create(:access, user: admin, role: :admin, resource: facility_1) }

    permissions :allowed? do
      it "allows the user" do
        expect(subject).to permit(admin, facility_1)
      end

      it "denies the user" do
        expect(subject).not_to permit(admin, facility_2)
      end
    end
  end
end

RSpec.describe Upcoming::Manage::FacilityPolicy::Scope do
  let(:subject) { described_class }
  let(:organization) { create(:organization) }
  let!(:facility_group_1) { create(:facility_group, organization: organization) }
  let!(:facility_group_2) { create(:facility_group, organization: organization) }
  let!(:facility_1) { create(:facility, facility_group: facility_group_1) }
  let!(:facility_2) { create(:facility, facility_group: facility_group_2) }
  let!(:facility_3) { create(:facility) }

  context "user can manage all facilities" do
    let!(:super_admin) { create(:admin) }
    let!(:super_admin_access) { create(:access, user: super_admin, role: :super_admin, resource: nil) }

    it "resolve all facilities" do
      resolved_records = subject.new(super_admin, Facility).resolve
      expect(resolved_records).to match_array(Facility.all)
    end
  end

  context "user can manage facilities for an organization" do
    let!(:admin) { create(:admin) }
    let!(:admin_access) { create(:access, user: admin, role: :admin, resource: organization) }

    it "resolves all facilities in their organization" do
      resolved_records = subject.new(admin, Facility).resolve
      expect(resolved_records).to match_array([facility_1, facility_2])
    end
  end

  context "user can manage facilities for a facility group" do
    let!(:admin) { create(:admin) }
    let!(:admin_access) { create(:access, user: admin, role: :admin, resource: facility_group_1) }

    it "resolves all facilities in their facility group" do
      resolved_records = subject.new(admin, Facility).resolve
      expect(resolved_records).to match_array([facility_1])
    end
  end

  context "user can manage a single facility" do
    let!(:admin) { create(:admin) }
    let!(:admin_access) { create(:access, user: admin, role: :admin, resource: facility_1) }

    it "resolves their facility" do
      resolved_records = subject.new(admin, Facility).resolve
      expect(resolved_records).to match_array([facility_1])
    end
  end

  context "other users" do
    let(:other_user) { create(:admin) }

    it "resolves an empty set" do
      resolved_records = subject.new(other_user, Facility).resolve
      expect(resolved_records).to be_empty
    end
  end
end
