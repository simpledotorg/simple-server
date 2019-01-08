require "rails_helper"

RSpec.describe AuditLogPolicy do
  subject { described_class }

  let(:owner) { create(:admin, :owner) }
  let(:organization_owner) { create(:admin, :organization_owner) }
  let(:supervisor) { create(:admin, :supervisor) }
  let(:analyst) { create(:admin, :analyst) }

  permissions :index?, :show? do
    it "permits owners" do
      expect(subject).to permit(owner, AuditLog)
    end

    it "permits supervisors" do
      expect(subject).not_to permit(supervisor, AuditLog)
    end

    it "permits analysts" do
      expect(subject).not_to permit(analyst, AuditLog)
    end

    it "permits organization owners" do
      expect(subject).not_to permit(organization_owner, AuditLog)
    end
  end
end

RSpec.describe AuditLogPolicy::Scope do
  let(:subject) { described_class }

  before :each do
    FactoryBot.create_list(:audit_log, 20)
  end

  describe "owner" do
    let(:owner) { FactoryBot.create(:admin, :owner) }

    it "resolves all audit logs" do
      resolved_records = subject.new(owner, AuditLog.all).resolve
      expect(resolved_records.to_a).to match_array(AuditLog.all.to_a)
    end
  end

  describe "organization owner" do
    let(:organization_owner) { FactoryBot.create(:admin, :organization_owner) }
    it "resolves no audit logs" do
      resolved_records = subject.new(organization_owner, AuditLog.all).resolve
      expect(resolved_records).to be_empty
    end
  end

  describe "supervisor" do
    let(:supervisor) { FactoryBot.create(:admin, :supervisor) }
    it "resolves no audit logs" do
      resolved_records = subject.new(supervisor, AuditLog.all).resolve
      expect(resolved_records).to be_empty
    end
  end

  describe "analyst" do
    let(:analyst) { FactoryBot.create(:admin, :analyst) }
    it "resolves no audit logs" do
      resolved_records = subject.new(analyst, AuditLog.all).resolve
      expect(resolved_records).to be_empty
    end
  end
end