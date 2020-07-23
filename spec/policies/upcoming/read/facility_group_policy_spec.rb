require "rails_helper"

RSpec.describe Upcoming::Read::FacilityGroupPolicy::Scope do
  let(:subject) { described_class }
  let(:organization) { create(:organization) }
  let!(:facility_group_1) { create(:facility_group, organization: organization) }
  let!(:facility_group_2) { create(:facility_group, organization: organization) }
  let!(:facility_group_3) { create(:facility_group) }

  context "user can view all facility groups" do
    let!(:super_admin) { create(:admin) }
    let!(:super_admin_access) { create(:access, user: super_admin, role: :super_admin, resource: nil) }

    it "resolve all facility groups" do
      resolved_records = subject.new(super_admin, FacilityGroup).resolve
      expect(resolved_records).to include(facility_group_1, facility_group_2, facility_group_3)
    end
  end

  context "user can view facility groups for an organization" do
    let!(:analyst) { create(:admin) }
    let!(:view_access) { create(:access, user: analyst, role: :analyst, resource: organization) }

    it "resolves all facility groups in their organization" do
      resolved_records = subject.new(analyst, FacilityGroup).resolve
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
