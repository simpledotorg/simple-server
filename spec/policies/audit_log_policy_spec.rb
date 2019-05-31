require "rails_helper"

RSpec.describe AuditLogPolicy do
  subject { described_class }

  let(:user_can_manage_all_organizations) do
    user = create(:master_user)
    create(:user_permission, user: user, permission_slug: :can_manage_all_organizations, resource: nil)
    user
  end

  let(:other_user) { create(:master_user) }

  permissions :index?, :show? do
    it "permits users who can manage all organizations" do
      expect(subject).to permit(user_can_manage_all_organizations, AuditLog)
    end

    it "denies all other users" do
      expect(subject).not_to permit(other_user, AuditLog)
    end

  end
end

RSpec.describe AuditLogPolicy::Scope do
  let(:subject) { described_class }

  before :each do
    FactoryBot.create_list(:audit_log, 20)
  end

  let(:user_can_manage_all_organizations) do
    user = create(:master_user)
    create(:user_permission, user: user, permission_slug: :can_manage_all_organizations, resource: nil)
    user
  end

  let(:other_user) { create(:master_user) }

  it "resolves all audit logs for users who can manage all organizations" do
    resolved_records = subject.new(user_can_manage_all_organizations, AuditLog.all).resolve
    expect(resolved_records.to_a).to match_array(AuditLog.all.to_a)
  end

  it "resolves no records for other users" do
    resolved_records = subject.new(other_user, AuditLog.all).resolve
    expect(resolved_records).to be_empty
  end
end