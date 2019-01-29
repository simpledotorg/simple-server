require "rails_helper"

RSpec.describe FacilityGroupPolicy do
  subject { described_class }

  let(:organization) { FactoryBot.create(:organization) }
  let!(:facility_group_in_organization) { FactoryBot.create(:facility_group, organization: organization) }
  let!(:facility_group_outside_organization) { FactoryBot.create(:facility_group) }

  let(:owner) { FactoryBot.create(:admin, :owner) }
  let(:organization_owner) { FactoryBot.create(:admin, :organization_owner, admin_access_controls: [AdminAccessControl.new(access_controllable: organization)]) }
  let(:supervisor) { FactoryBot.create(:admin, :supervisor, admin_access_controls: [AdminAccessControl.new(access_controllable: facility_group_in_organization)]) }
  let(:analyst) { FactoryBot.create(:admin, :analyst) }

  permissions :index?, :new?, :create? do
    it "permits owners and organization owners" do
      new_facility_group = organization.facility_groups.new
      expect(subject).to permit(owner, FacilityGroup)
      expect(subject).to permit(organization_owner, FacilityGroup)
      expect(subject).to permit(organization_owner, new_facility_group)
    end

    it "denies supervisors and analysts" do
      expect(subject).not_to permit(supervisor, FacilityGroup)
      expect(subject).not_to permit(analyst, FacilityGroup)
    end
  end

  permissions :show?, :update?, :edit?, :destroy? do
    it "permits owners for all facility groups" do
      expect(subject).to permit(owner, facility_group_in_organization)
      expect(subject).to permit(owner, facility_group_outside_organization)
    end

    it "permits organization owners only for facility groups in their organizations" do
      expect(subject).to permit(organization_owner, facility_group_in_organization)
      expect(subject).not_to permit(organization_owner, facility_group_outside_organization)
    end

    it "denies supervisors and analysts" do
      expect(subject).not_to permit(supervisor, FacilityGroup)
      expect(subject).not_to permit(analyst, FacilityGroup)
    end
  end
end

RSpec.describe FacilityGroupPolicy::Scope do
  let(:subject) { described_class }
  let(:organization) { create(:organization) }
  let!(:facility_group_1) { create(:facility_group, organization: organization) }
  let!(:facility_group_2) { create(:facility_group, organization: organization) }
  let!(:facility_group_3) { create(:facility_group) }

  describe "owner" do
    let(:owner) { create(:admin, :owner) }
    it "resolves all facility groups" do
      resolved_records = subject.new(owner, FacilityGroup.all).resolve
      expect(resolved_records.to_a).to match_array(FacilityGroup.all.to_a)
    end
  end

  describe "organization owner" do
    let(:organization_owner) {
      create(:admin,
             :organization_owner,
             admin_access_controls: [AdminAccessControl.new(access_controllable: organization)]
      ) }
    it "resolves facility groups for their organizations" do
      resolved_records = subject.new(organization_owner, FacilityGroup.all).resolve
      expect(resolved_records).to match_array([facility_group_1, facility_group_2])
    end
  end

  describe "supervisor" do
    let(:supervisor) {
      create(:admin,
             :supervisor,
             admin_access_controls: [
               AdminAccessControl.new(access_controllable: facility_group_1),
               AdminAccessControl.new(access_controllable: facility_group_2)
             ])
    }
    it "resolves to their facility groups" do
      resolved_records = subject.new(supervisor, FacilityGroup.all).resolve
      expect(resolved_records).to match_array([facility_group_1, facility_group_2])
    end
  end

  describe "analyst" do
    let(:analyst) {
      create(:admin,
             :analyst,
             admin_access_controls: [
               AdminAccessControl.new(access_controllable: facility_group_1),
               AdminAccessControl.new(access_controllable: facility_group_2)
             ])
    }
    it "resolves to their facility groups" do
      resolved_records = subject.new(analyst, FacilityGroup.all).resolve
      expect(resolved_records).to match_array([facility_group_1, facility_group_2])
    end
  end
end