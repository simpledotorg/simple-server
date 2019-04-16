require "rails_helper"

RSpec.describe OrganizationPolicy do
  subject { described_class }

  let(:organization) { FactoryBot.create(:organization) }

  let(:owner) { create(:admin, :owner) }
  let(:organization_owner) { FactoryBot.create(:admin, :organization_owner, admin_access_controls: [AdminAccessControl.new(access_controllable: organization)]) }
  let(:supervisor) { FactoryBot.create(:admin, :supervisor) }
  let(:analyst) { create(:admin, :analyst) }

  permissions :index? do
    it "permits owners" do
      expect(subject).to permit(owner, Organization)
    end

    it "permits organization owners" do
      expect(subject).to permit(organization_owner, Organization)
    end

    it "denies supervisors" do
      expect(subject).not_to permit(supervisor, Organization)
    end

    it "denies analysts" do
      expect(subject).not_to permit(analyst, Organization)
    end
  end

  permissions :show?, :new?, :create?, :update?, :edit? do
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

  permissions :show?, :update?, :edit? do
    it "permits organization owners only for their organizations" do
      other_organization = FactoryBot.create(:organization)
      expect(subject).to permit(organization_owner, organization)
      expect(subject).not_to permit(organization_owner, other_organization)
    end
  end

  permissions :destroy? do
    it "permits owners" do
      expect(subject).to permit(owner, organization)
    end

    it "denies organization owners" do
      expect(subject).not_to permit(organization_owner, organization)
    end

    it "denies supervisors" do
      expect(subject).not_to permit(supervisor, organization)
    end

    it "denies analysts" do
      expect(subject).not_to permit(analyst, organization)
    end

    context "with associated facility_groups" do
      before do
        create(:facility_group, organization: organization)
      end

      it "denies everyone" do
        expect(subject).not_to permit(owner, organization)
      end
    end
  end
end

RSpec.describe OrganizationPolicy::Scope do
  let(:subject) { described_class }
  let(:organization_1) { create(:organization) }
  let(:organization_2) { create(:organization) }

  let(:facility_group_1) { create(:facility_group, organization: organization_1) }
  let(:facility_group_2) { create(:facility_group, organization: organization_2) }

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
