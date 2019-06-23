require "rails_helper"

RSpec.describe AuditLogPolicy do
  subject { described_class }

  context 'user with permission to manage audit logs' do
    let(:user_with_permission) do
      create(:user, permissions: [:can_manage_audit_logs])
    end

    permissions :index? do
      it 'allows the user to view all audit logs' do
        expect(subject).to permit(user_with_permission, AuditLog)
      end
    end

    permissions :show? do
      it 'allows the user to view all audit logs' do
        audit_log = build(:audit_log)
        expect(subject).to permit(user_with_permission, audit_log)
      end
    end
  end

  context 'other users' do
    let(:other_user) do
      create(:user, permissions: [])
    end

    permissions :index? do
      it 'allows the user to view all audit logs' do
        expect(subject).not_to permit(other_user, AuditLog)
      end
    end

    permissions :show? do
      it 'allows the user to view all audit logs' do
        audit_log = build(:audit_log)
        expect(subject).not_to permit(other_user, audit_log)
      end
    end
  end
end

RSpec.describe AuditLogPolicy::Scope do
  let(:subject) { described_class }

  before :each do
    FactoryBot.create_list(:audit_log, 3)
  end

  context 'user with permission to manage audit logs' do
    let(:user_with_permission) do
      create(:user, permissions: [:can_manage_audit_logs])
    end

    it 'resolves all audit logs' do
      resolved_records = subject.new(user_with_permission, AuditLog.all).resolve
      expect(resolved_records).to match_array(AuditLog.all)
    end
  end

  context 'other users' do
    let(:other_user) do
      create(:user, permissions: [])
    end

    it 'resolves an empty set' do
      resolved_records = subject.new(other_user, AuditLog.all).resolve
      expect(resolved_records).to be_empty
    end
  end
end