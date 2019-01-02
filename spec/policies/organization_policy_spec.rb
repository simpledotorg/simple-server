require "rails_helper"

RSpec.describe OrganizationPolicy do
  subject { described_class }

  let(:owner) { create(:admin, :owner) }
  let(:supervisor) { create(:admin, :supervisor) }
  let(:analyst) { create(:admin, :analyst) }

  permissions :index?, :show?, :new?, :create?, :update?, :edit?, :destroy? do
    it "permits owners" do
      expect(subject).to permit(owner, Organization)
    end

    it "denies supervisors" do
      expect(subject).not_to permit(supervisor, Organization)
    end

    it "denies analysts" do
      expect(subject).not_to permit(analyst, Organization)
    end
  end
end

RSpec.describe OrganizationPolicy::Scope do
  let(:subject) { described_class }
  let(:organization_1) { create(:organization) }
  let(:organization_2) { create(:organization) }

  let(:facility_group_1) { create(:facility_group, organization: organization_1)}
  let(:facility_group_2) { create(:facility_group, organization: organization_2)}

  describe "owner" do
    let(:owner) { create(:admin, :owner) }
    it "resolves all organizations" do
      resolved_records = subject.new(owner, Organization.all).resolve
      expect(resolved_records.to_a).to match_array(Organization.all.to_a)
    end
  end

  describe "organization owner" do
    let(:organization_owner) {
      create(:admin,
             :organization_owner,
             admin_access_controls: [AdminAccessControl.new(access_controllable: organization_1)]
      ) }
    it "resolves their organizations" do
      resolved_records = subject.new(organization_owner, Organization.all).resolve
      expect(resolved_records).to match_array([organization_1])
    end
  end

  describe "supervisor" do
    let(:supervisor) {
      create(:admin,
             :supervisor,
             admin_access_controls: [AdminAccessControl.new(access_controllable: facility_group_1)])
    }
    it "resolves their organization" do
      resolved_records = subject.new(supervisor, Organization.all).resolve
      expect(resolved_records).to match_array([organization_1])
    end
  end

  describe "analyst" do
    let(:analyst) {
      create(:admin,
             :analyst,
             admin_access_controls: [AdminAccessControl.new(access_controllable: facility_group_1)])
    }
    it "resolves their organization" do
      resolved_records = subject.new(analyst, Organization.all).resolve
      expect(resolved_records).to match_array([organization_1])
    end
  end
end