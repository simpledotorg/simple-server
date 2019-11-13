require "rails_helper"

RSpec.describe ProtocolPolicy do
  subject { described_class }

  let(:owner) { create(:admin, :owner) }
  let(:supervisor) { create(:admin, :supervisor) }
  let(:analyst) { create(:admin, :analyst) }

  permissions :index?, :show?, :new?, :create?, :update?, :edit?, :destroy? do
    it "permits owners" do
      expect(subject).to permit(owner, Protocol)
    end

    it "denies supervisors" do
      expect(subject).not_to permit(supervisor, Protocol)
    end

    it "denies analysts" do
      expect(subject).not_to permit(analyst, Protocol)
    end
  end
end

RSpec.describe ProtocolPolicy::Scope do
  let(:subject) { described_class }
  let(:organization) { create(:organization) }

  let(:protocol_1) { create(:protocol) }
  let(:protocol_2) { create(:protocol) }

  let!(:facility_group_1) { create(:facility_group, organization: organization, protocol: protocol_1) }
  let!(:facility_group_2) { create(:facility_group, organization: organization, protocol: protocol_2) }

  describe "owner" do
    let(:owner) { create(:admin, :owner) }
    it "resolves protocols" do
      resolved_records = subject.new(owner, Protocol.all).resolve
      expect(resolved_records.to_a).to match_array(Protocol.all.to_a)
    end
  end

  describe "organization owner" do
    let(:organization_owner) {
      create(:admin,
             :organization_owner,
             admin_access_controls: [AdminAccessControl.new(access_controllable: organization)]
      ) }
    it "resolves all protocols in their organizations" do
      resolved_records = subject.new(organization_owner, Protocol.all).resolve
      expect(resolved_records).to match_array([protocol_1, protocol_2])
    end
  end

  describe "supervisor" do
    let(:supervisor) {
      create(:admin,
             :supervisor,
             admin_access_controls: [AdminAccessControl.new(access_controllable: facility_group_1)])
    }
    it "resolves all protocols in their facility groups" do
      resolved_records = subject.new(supervisor, Protocol.all).resolve
      expect(resolved_records).to match_array([protocol_1])
    end
  end

  describe "analyst" do
    let(:analyst) {
      create(:admin,
             :analyst,
             admin_access_controls: [AdminAccessControl.new(access_controllable: facility_group_1)])
    }
    it "resolves all protocols in their facility groups" do
      resolved_records = subject.new(analyst, Protocol.all).resolve
      expect(resolved_records).to match_array([protocol_1])
    end
  end
end