require "rails_helper"

RSpec.describe Upcoming::Read::FacilityPolicy::Scope do
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
      expect(resolved_records).to include(facility_1, facility_2, facility_3)
    end
  end

  context "user can manage facilities for an organization" do
    let!(:admin) { create(:admin) }
    let!(:admin_access) { create(:access, user: admin, role: :admin, resource: organization) }

    it "resolves all facilities in their organization" do
      resolved_records = subject.new(admin, Facility).resolve
      expect(resolved_records).to include(facility_1, facility_2)
      expect(resolved_records).not_to include(facility_3)
    end
  end

  context "user can manage facilities for a facility group" do
    let!(:admin) { create(:admin) }
    let!(:admin_access) { create(:access, user: admin, role: :admin, resource: facility_group_1) }

    it "resolves all facilities in their facility group" do
      resolved_records = subject.new(admin, Facility).resolve
      expect(resolved_records).to include(facility_1)
      expect(resolved_records).not_to include(facility_2, facility_3)
    end
  end

  context "user can manage a single facility" do
    let!(:admin) { create(:admin) }
    let!(:admin_access) { create(:access, user: admin, role: :admin, resource: facility_1) }

    it "resolves their facility" do
      resolved_records = subject.new(admin, Facility).resolve
      expect(resolved_records).to include(facility_1)
      expect(resolved_records).not_to include(facility_2, facility_3)
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
