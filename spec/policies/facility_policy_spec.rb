require "rails_helper"

RSpec.describe FacilityPolicy do
  subject { described_class }

  let(:owner) { create(:admin, :owner) }
  let(:supervisor) { create(:admin, :supervisor) }
  let(:analyst) { create(:admin, :analyst) }

  permissions :index?, :show? do
    it "permits owners" do
      expect(subject).to permit(owner, Facility)
    end

    it "permits supervisors" do
      expect(subject).to permit(supervisor, Facility)
    end

    it "denies analysts" do
      expect(subject).not_to permit(analyst, Facility)
    end
  end

  permissions :new?, :create?, :update?, :edit?, :destroy? do
    it "permits owners" do
      expect(subject).to permit(owner, Facility)
    end

    it "denies supervisors" do
      expect(subject).not_to permit(supervisor, Facility)
    end

    it "denies analysts" do
      expect(subject).not_to permit(analyst, Facility)
    end
  end
end

RSpec.describe FacilityPolicy::Scope do
  let(:subject) { described_class }
  let(:organization) { create(:organization) }
  let(:facility_group) { create(:facility_group, organization: organization) }
  let!(:facility_1) { create(:facility, facility_group: facility_group) }
  let!(:facility_2) { create(:facility, facility_group: facility_group) }
  let!(:facility_3) { create(:facility) }

  describe "owner" do
    let(:owner) { create(:admin, :owner) }
    it "resolves all facilities" do
      resolved_records = subject.new(owner, Facility.all).resolve
      expect(resolved_records.to_a).to match_array(Facility.all.to_a)
    end
  end

  describe "organization owner" do
    let(:organization_owner) {
      create(:admin,
             :organization_owner,
             admin_access_controls: [AdminAccessControl.new(access_controllable: organization)]
      ) }
    it "resolves facility for their organizations" do
      resolved_records = subject.new(organization_owner, Facility.all).resolve
      expect(resolved_records).to match_array([facility_1, facility_2])
    end
  end

  describe "supervisor" do
    let(:supervisor) {
      create(:admin,
             :supervisor,
             admin_access_controls: [AdminAccessControl.new(access_controllable: facility_group)])
    }
    it "resolves facilities of their facility groups" do
      resolved_records = subject.new(supervisor, Facility.all).resolve
      expect(resolved_records).to match_array([facility_1, facility_2])
    end
  end

  describe "analyst" do
    let(:analyst) {
      create(:admin,
             :analyst,
             admin_access_controls: [AdminAccessControl.new(access_controllable: facility_group)])
    }
    it "resolves facilities of their facility groups" do
      resolved_records = subject.new(analyst, Facility.all).resolve
      expect(resolved_records).to match_array([facility_1, facility_2])
    end
  end
end