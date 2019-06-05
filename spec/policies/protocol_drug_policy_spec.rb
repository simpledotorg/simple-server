require "rails_helper"

RSpec.describe ProtocolDrugPolicy do
  subject { described_class }

  let(:owner) { create(:admin, :owner) }
  let(:supervisor) { create(:admin, :supervisor) }
  let(:analyst) { create(:admin, :analyst) }

  permissions :index?, :show?, :new?, :create?, :update?, :edit?, :destroy? do
    it "permits owners" do
      expect(subject).to permit(owner, ProtocolDrug)
    end

    it "permits organization owners" do
      expect(subject).to permit(owner, ProtocolDrug)
    end

    it "denies supervisors" do
      expect(subject).not_to permit(supervisor, ProtocolDrug)
    end

    it "denies analysts" do
      expect(subject).not_to permit(analyst, ProtocolDrug)
    end
  end
end

RSpec.describe ProtocolDrugPolicy::Scope do
  let(:subject) { described_class }
  let(:organization) { create(:organization) }

  let(:protocol_1) { create(:protocol) }
  let(:protocol_2) { create(:protocol) }
  let!(:protocol_drugs_1) { create_list(:protocol_drug, 5, protocol: protocol_1) }
  let!(:protocol_drugs_2) { create_list(:protocol_drug, 5, protocol: protocol_2) }

  let!(:facility_group_1) { create(:facility_group, organization: organization, protocol: protocol_1) }
  let!(:facility_group_2) { create(:facility_group, organization: organization, protocol: protocol_2) }

  describe "owner" do
    let(:owner) { create(:admin, :owner) }
    it "resolves all protocol drugs" do
      resolved_records = subject.new(owner, ProtocolDrug.all).resolve
      expect(resolved_records.to_a).to match_array(ProtocolDrug.all.to_a)
    end
  end

  describe "organization owner" do
    let(:organization_owner) {
      create(:admin,
             :organization_owner,
             admin_access_controls: [AdminAccessControl.new(access_controllable: organization)]
      ) }
    it "resolves all protocol drugs their organizations" do
      resolved_records = subject.new(organization_owner, ProtocolDrug.all).resolve
      expect(resolved_records).to match_array(protocol_drugs_1 + protocol_drugs_2)
    end
  end

  describe "supervisor" do
    let(:supervisor) {
      create(:admin,
             :supervisor,
             admin_access_controls: [AdminAccessControl.new(access_controllable: facility_group_1)])
    }
    it "resolves all protocol drugs their facility groups" do
      resolved_records = subject.new(supervisor, ProtocolDrug.all).resolve
      expect(resolved_records).to match_array(protocol_drugs_1)
    end
  end

  describe "analyst" do
    let(:analyst) {
      create(:admin,
             :analyst,
             admin_access_controls: [AdminAccessControl.new(access_controllable: facility_group_1)])
    }
    it "resolves all protocol drugs in their facility groups" do
      resolved_records = subject.new(analyst, ProtocolDrug.all).resolve
      expect(resolved_records).to match_array(protocol_drugs_1)
    end
  end
end
