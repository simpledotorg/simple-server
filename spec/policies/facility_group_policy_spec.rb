require "rails_helper"

RSpec.describe FacilityGroupPolicy do
  subject { described_class }

  let(:owner) { create(:admin, :owner) }
  let(:supervisor) { create(:admin, :supervisor) }
  let(:analyst) { create(:admin, :analyst) }

  permissions :index?, :show?, :new?, :create?, :update?, :edit?, :destroy? do
    it "permits owners" do
      expect(subject).to permit(owner, FacilityGroup)
    end

    it "denies supervisors" do
      expect(subject).not_to permit(supervisor, FacilityGroup)
    end

    it "denies analysts" do
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